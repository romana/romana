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
	"bytes"
	"encoding/json"
	"fmt"
	"flag"
	"net/http"
	"os"
	"path"
	"net/url"

	// aws-sdk-go imports
	"github.com/aws/aws-sdk-go/aws/ec2metadata"
	"github.com/aws/aws-sdk-go/aws/session"
)

var (
	romanaAwsUrl = flag.String("romana-aws", "", "Full address of romana-aws service")
	enabled = flag.Bool("enabled", false, "Value to set for SourceDestCheck")
)

func main() {
	flag.Parse()

	if *romanaAwsUrl == "" {
		fmt.Fprintf(os.Stderr, "The option --romana-aws must be provided\n")
		os.Exit(1)
	}

	targetURL, err := url.Parse(*romanaAwsUrl)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Unable to parse value for --romana-aws: %s", err)
		os.Exit(1)
	}
	targetURL.Path = path.Join(targetURL.Path,  "/", "ec2", "instanceAttributes")

	sess, err := session.NewSession()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error initializing AWS session: %s\n", err)
		os.Exit(1)
	}

	mdSvc := ec2metadata.New(sess)
	if ! mdSvc.Available() {
		fmt.Fprintf(os.Stderr, "Metadata service not available\n")
		os.Exit(1)
	}

	id, err := mdSvc.GetInstanceIdentityDocument()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error requesting Instance Identity Document: %s\n", err)
		os.Exit(1)
	}
	if id.Region == "" {
		fmt.Fprintf(os.Stderr, "Instance Metadata contains empty Region\n")
		os.Exit(1)
	}
	if id.InstanceID == "" {
		fmt.Fprintf(os.Stderr, "Instance Metadata contains empty InstanceID\n")
		os.Exit(1)
	}

	// Build the request
	reqData := struct {
		Region string `json:"region"`
		InstanceID string `json:"instanceID"`
		SourceDestCheck *bool `json:"sourceDestCheck"`
	}{
		Region: id.Region,
		InstanceID: id.InstanceID,
		SourceDestCheck: enabled,
	}
	reqBody, err := json.Marshal(reqData)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error marshaling data for romana-aws request: %s\n", err)
		os.Exit(1)
	}

	res, err := http.Post(targetURL.String(), "application/json", bytes.NewReader(reqBody))
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error sending request to romana-aws: %s\n", err)
		os.Exit(1)
	}
	if res.StatusCode != http.StatusOK {
		fmt.Fprintf(os.Stderr, "Unexpected status from romana-aws: %s\n", res.Status)
		os.Exit(1)
	}
}
