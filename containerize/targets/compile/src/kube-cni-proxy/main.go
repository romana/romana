// Copyright (c) 2016 Pani Networks
// All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may
// not use this file except in compliance with the License. You may obtain
// a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.

// This package provides a proxy between kubernetes nodes using Romana CNI and
// Romana services running on a kubernetes master.
// When allocating an IP, the proxy looks up "labels" in the Kubernetes pod spec,
// and adds that to the IPAM request.
// When deallocating an IP, the proxy finds the IP previously allocated for the pod,
// and passes that to IPAM. (The interface on the node is deleted before CNI is triggered,
// so it can't be provided by the node directly.)
// An endpoint for looking up kubernetes namespace information is also provided.

package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"os/signal"
	"path"
	"path/filepath"
	"sync"
	"time"
)

var (
	port    = flag.Uint("port", 9609, "Port to listen for HTTP requests")
	target  = flag.String("target", "", "Target for the proxied HTTP requests. Must be a valid URL.")
	timeout = flag.String("timeout", "5s", "Duration before timing out a proxied request. Must be valid for Go's time.ParseDuration()")
	label   = flag.String("label", "romanaSegment", "Label to extract and use for romana segment")

	allocatedAddressDir = "/var/run/romana/ip-allocations"

	allocSegmentMutex = sync.Mutex{}
)

type romanaCNIRequest struct {
	Method    string `json:"-"`
	Host      string `json:"host"`
	Namespace string `json:"namespace"`
	PodName   string `json:"podName"`
}

func (r romanaCNIRequest) Incomplete() bool {
	switch r.Method {
	case "POST":
	case "DELETE":
	default:
		return true
	}
	switch {
	case r.Method == "POST" && r.Host == "":
		return true
	case r.Namespace == "":
		return true
	case r.PodName == "":
		return true
	}
	return false
}

func main() {
	flag.Parse()

	if *target == "" {
		fmt.Fprintf(os.Stderr, "No target URL provided\n")
		flag.Usage()
		return
	}
	// Check that we can build requests using the provided URL
	_, err := url.Parse(*target)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error creating request with '%s': %s\n", *target, err)
		return
	}
	// Check that we can parse the timeout duration
	t, err := time.ParseDuration(*timeout)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error parsing duration '%s': %s\n", *timeout, err)
		return
	}
	// Set timeout for http.DefaultClient
	http.DefaultClient.Timeout = t

	// Add our http handler
	http.HandleFunc("/endpoints", endpointsHandler)
	http.HandleFunc("/namespaces", namespacesHandler)

	// Initialize allocatedAddressDir
	err = os.MkdirAll(allocatedAddressDir, 0700)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error creating '%s': %s\n", allocatedAddressDir, err)
		return
	}

	// Set up server
	server := http.Server{Addr: fmt.Sprintf(":%d", *port)}
	server.SetKeepAlivesEnabled(false)

	// Launch server, report initialization errors.
	errCh := make(chan struct{})
	go func() {
		defer close(errCh)
		ln, err := net.Listen("tcp", server.Addr)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error from net.Listen: %s\n", err)
			return
		}
		err = server.Serve(ln)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error from server.Serve: %s\n", err)
			return
		}
	}()

	// Add signal handler for Ctrl-C
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, os.Interrupt, os.Kill)

	// Block until error or Ctrl-C
	select {
	case <-sigCh:
	case <-errCh:
	}
}

// handle a request to the CNI endpoint
func endpointsHandler(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case "POST":
		cniPostRequest(w, r)
	case "DELETE":
		cniDeleteRequest(w, r)
	default:
		http.Error(w, "Only POST and DELETE supported", http.StatusMethodNotAllowed)
	}
}

func cniPostRequest(w http.ResponseWriter, r *http.Request) {
	// Decode request body
	reqData := romanaCNIRequest{Method: r.Method}
	// TODO: Consider replacing calls to json.NewDecoder().Decode with json.Unmarshal
	err := json.NewDecoder(&io.LimitedReader{R: r.Body, N: 1 << 16}).Decode(&reqData)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error decoding request: %s", err), 422) // http.StatusUnprocessableEntity
		return
	}
	if reqData.Incomplete() {
		http.Error(w, "romanaCNIRequest incomplete", 422) // http.StatusUnprocessableEntity
		return
	}
	// Look up pod information using kubectl
	cmd := exec.Command("kubectl", "--namespace="+reqData.Namespace, "get", "pod", reqData.PodName, "-o", "json")
	cmdData, err := cmd.Output()
	if err != nil {
		http.Error(w, fmt.Sprintf("Error invoking kubectl for namespace '%s' and pod '%s': %s", reqData.Namespace, reqData.PodName, err), http.StatusInternalServerError)
		return
	}
	// One-off data structure for the JSON result
	podData := struct {
		Metadata struct {
			Labels map[string]string `json:"labels"`
		} `json:"metadata"`
	}{}
	segment := "default"
	err = json.Unmarshal(cmdData, &podData)
	// Note: only overwrite segment if a value was extracted
	// so check == nil.
	if err == nil {
		if v, ok := podData.Metadata.Labels[*label]; ok {
			segment = v
		}
	}

	// Automagically allocate the segment
	cmd = exec.Command("auto-create-segment", reqData.Namespace, segment)
	// guard this execution with a mutex, otherwise it may be racey
	allocSegmentMutex.Lock()
	err = cmd.Run()
	allocSegmentMutex.Unlock()
	if err != nil {
		// ignore this and continue attempting IPAM allocation
	}

	// Submit request to IPAM
	ipamReq, err := http.NewRequest("GET", *target, nil)
	if err != nil {
		http.Error(w, "Unable to create request to target", http.StatusInternalServerError)
		return
	}
	ipamReq.URL.Path = path.Join(ipamReq.URL.Path, "/allocateIP")
	query := url.Values{}
	query.Set("hostName", reqData.Host)
	query.Set("tenantName", reqData.Namespace)
	query.Set("segmentName", segment)
	query.Set("instanceName", reqData.PodName)
	ipamReq.URL.RawQuery = query.Encode()

	ipamRes, err := http.DefaultClient.Do(ipamReq)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error during request to %s: %s", ipamReq.URL, err), http.StatusBadGateway)
		return
	}
	defer ipamRes.Body.Close()

	// Create a file that will hold the data received from IPAM
	f, err := os.Create(filepath.Join(allocatedAddressDir, reqData.Namespace+":"+reqData.PodName))
	if err != nil {
		// Not sure what to do about this
	}

	// Copy the data through
	w.WriteHeader(ipamRes.StatusCode)
	if f != nil {
		io.Copy(io.MultiWriter(w, f), ipamRes.Body)
		f.Close()
	} else {
		io.Copy(w, ipamRes.Body)
	}
}

func cniDeleteRequest(w http.ResponseWriter, r *http.Request) {
	// Decode request body
	reqData := romanaCNIRequest{Method: r.Method}
	err := json.NewDecoder(&io.LimitedReader{R: r.Body, N: 1 << 16}).Decode(&reqData)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error decoding request: %s", err), 422) // http.StatusUnprocessableEntity
		return
	}
	if reqData.Incomplete() {
		http.Error(w, "romanaCNIRequest incomplete", 422) // http.StatusUnprocessableEntity
		return
	}
	// Look for a file containing state information
	filename := filepath.Join(allocatedAddressDir, reqData.Namespace+":"+reqData.PodName)
	f, err := os.Open(filename)
	if err != nil {
		if os.IsNotExist(err) {
			http.Error(w, fmt.Sprintf("allocation info for address for '%s:%s' not found", reqData.Namespace, reqData.PodName), http.StatusNotFound)
			return
		}
		http.Error(w, fmt.Sprintf("Failed to open: %s", err), http.StatusInternalServerError)
		return
	}

	// Load IP address from file
	ipamData := struct {
		IP string `json:"ip"`
	}{}
	err = json.NewDecoder(f).Decode(&ipamData)
	if err != nil {
		http.Error(w, fmt.Sprintf("failed to extract stored IP address for '%s:%s':%s", reqData.Namespace, reqData.PodName, err), http.StatusInternalServerError)
		return
	}
	if ipamData.IP == "" {
		http.Error(w, fmt.Sprintf("empty IP address for '%s:%s':%s", reqData.Namespace, reqData.PodName, err), http.StatusInternalServerError)
		return
	}

	// Submit DELETE request to IPAM
	ipamReq, err := http.NewRequest("DELETE", *target, nil)
	if err != nil {
		http.Error(w, "Unable to create request to target", http.StatusInternalServerError)
		return
	}
	ipamReq.URL.Path = path.Join(ipamReq.URL.Path, "/IPAMEndpoints", ipamData.IP)

	ipamRes, err := http.DefaultClient.Do(ipamReq)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error from request: %s", err), http.StatusBadGateway)
		return
	}
	defer ipamRes.Body.Close()

	// Copy the data through
	w.WriteHeader(ipamRes.StatusCode)
	io.Copy(w, ipamRes.Body)

	if ipamRes.StatusCode >= 200 && ipamRes.StatusCode < 300 {
		err = os.Remove(filename)
		if err != nil {
			// Still not sure what to do about this
		}
	}
}

func namespacesHandler(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case "GET":
		cniGetNamespace(w, r)
	default:
		http.Error(w, "Only GET supported", http.StatusMethodNotAllowed)
	}
}

func cniGetNamespace(w http.ResponseWriter, r *http.Request) {
	// Decode request
	q := r.URL.Query()
	namespace := q.Get("namespace")
	if namespace == "" {
		http.Error(w, "Error decoding request: missing namespace", 422) // http.StatusUnprocessableEntity
		return
	}
	// Look up pod information using kubectl
	cmd := exec.Command("kubectl", "get", "namespace", namespace, "-o", "json")
	cmdData, err := cmd.Output()
	if err != nil {
		http.Error(w, fmt.Sprintf("Error invoking kubectl for namespace '%s': %s", namespace, err), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write(cmdData)
}
