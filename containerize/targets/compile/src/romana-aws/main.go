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
	// stdlib imports
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"net"
	"net/http"
	"os"
	"os/signal"
	"time"

	// aws-sdk-go imports
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ec2"
)

var (
	// Maintain a global session instead of a per-request session.
	// This reduces the initialization required for each request.
	globalSession *session.Session

	// command-line flags
	port    = flag.Uint("port", 9660, "Port to listen for HTTP requests")
	timeout = flag.String("timeout", "5s", "Duration before timing out a request")
)

func main() {
	// Parse command-line flags
	flag.Parse()

	// Check that we can parse the timeout duration
	t, err := time.ParseDuration(*timeout)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error parsing duration '%s': %s\n", *timeout, err)
		return
	}

	// Initialize global session
	globalSession, err = session.NewSession()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error initializing global session %s\n", err)
		return
	}

	// TODO: create own http.ServeMux that logs requests and response statuses
	// instead of using DefaultServeMux. Register handler's / handlefuncs
	// on that mux.

	// Initialize handlers
	http.HandleFunc("/ec2/instanceAttributes", ec2InstanceAttributesHandler)

	// Set up server
	server := http.Server{
		Addr:         fmt.Sprintf(":%d", *port),
		ReadTimeout:  t,
		WriteTimeout: t,
	}

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

// instanceAttributes encapsulates the attributes of interest for
// an EC2 instance. Used for GET responses and POST requests.
type instanceAttributes struct {
	Region          string `json:"region"`
	InstanceID      string `json:"instanceID"`
	SourceDestCheck *bool  `json:"sourceDestCheck"`
}

// ec2InstanceAttributesHandler is invoked for HTTP requests to /ec2/instanceAttributes
// and dispatches to the GET/POST function based on request method.
// GET requires region and instanceID parameters
// POST requires JSON body containing region, instanceID and sourceDestCheck
func ec2InstanceAttributesHandler(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case "GET":
		getInstanceAttributes(w, r)
	case "POST":
		postInstanceAttributes(w, r)
	default:
		http.Error(w, "Only GET and POST supported", http.StatusMethodNotAllowed)
	}
}

// getInstanceAttributes handles the GET method for ec2InstanceAttributesHandler
// Parameters region and instanceID are required. The response is in JSON.
func getInstanceAttributes(w http.ResponseWriter, r *http.Request) {
	vals := r.URL.Query()
	region := vals.Get("region")
	if region == "" {
		http.Error(w, "Error decoding request: missing region", http.StatusUnprocessableEntity)
		return
	}
	instanceID := vals.Get("instanceID")
	if instanceID == "" {
		http.Error(w, "Error decoding request: missing instanceID", http.StatusUnprocessableEntity)
		return
	}

	ec2Client := ec2.New(globalSession, aws.NewConfig().WithRegion(region))
	ec2Req := &ec2.DescribeInstancesInput{
		InstanceIds: []*string{aws.String(instanceID)},
	}

	// This is a bit excessive, but "proper" for AWS APIs.
	instances := []*ec2.Instance{}
	err := ec2Client.DescribeInstancesPages(ec2Req, func(page *ec2.DescribeInstancesOutput, lastPage bool) bool {
		for _, rv := range page.Reservations {
			for _, v := range rv.Instances {
				instances = append(instances, v)
			}
		}
		return true
	})
	if err != nil {
		http.Error(w, fmt.Sprintf("Error requesting information for instance %s in region %s: %s", instanceID, region, err), http.StatusUnprocessableEntity)
		return
	}

	// instance not found
	if len(instances) == 0 {
		http.Error(w, fmt.Sprintf("Error requesting information for instance %s in region %s: not found", instanceID, region), http.StatusUnprocessableEntity)
		return
	}
	if len(instances) > 1 {
		http.Error(w, fmt.Sprintf("Error requesting information for instance %s in region %s: %d found", instanceID, region, len(instances)), http.StatusUnprocessableEntity)
		return
	}

	attrs := instanceAttributes{
		Region:          region,
		InstanceID:      instanceID,
		SourceDestCheck: instances[0].SourceDestCheck,
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	body, err := json.Marshal(attrs)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error generating response for instance %s in region %s: %s", instanceID, region, err), http.StatusUnprocessableEntity)
		return
	}
	w.Write(body)
}

// postInstanceAttributes handles the POST method for ec2InstanceAttributesHandler
// A JSON body containing region, instanceID and sourceDestCheck is required.
// The response is a HTTP status
func postInstanceAttributes(w http.ResponseWriter, r *http.Request) {
	// Decode request body
	attrs := instanceAttributes{}
	err := json.NewDecoder(&io.LimitedReader{R: r.Body, N: 1 << 16}).Decode(&attrs)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error decoding request: %s", err), http.StatusUnprocessableEntity)
		return
	}
	if attrs.Region == "" {
		http.Error(w, "Error decoding request: missing region", http.StatusUnprocessableEntity)
		return
	}
	if attrs.InstanceID == "" {
		http.Error(w, "Error decoding request: missing instanceID", http.StatusUnprocessableEntity)
		return
	}
	if attrs.SourceDestCheck == nil {
		http.Error(w, "Error decoding request: missing sourceDestCheck", http.StatusUnprocessableEntity)
		return
	}

	ec2Client := ec2.New(globalSession, aws.NewConfig().WithRegion(attrs.Region))
	ec2Req := &ec2.ModifyInstanceAttributeInput{
		InstanceId:      &attrs.InstanceID,
		SourceDestCheck: &ec2.AttributeBooleanValue{Value: attrs.SourceDestCheck},
	}
	_, err = ec2Client.ModifyInstanceAttribute(ec2Req)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error requesting information for instance %s in region %s: %s", attrs.InstanceID, attrs.Region, err), http.StatusUnprocessableEntity)
		return
	}
	w.WriteHeader(http.StatusOK)
}
