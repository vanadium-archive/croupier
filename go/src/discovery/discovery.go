// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package discovery

import (
	"errors"
	"io/ioutil"
	"net/http"
	"strings"
)

func FindNamespace(host string) (string, error) {
	//Attempt to access the host website
	resp, err := http.Get(host)
	if err == nil {
		bytes, err := ioutil.ReadAll(resp.Body)
		if err == nil {
			//Successfully accessed the website!
			body := string(bytes)
			//Parse body looking for "v23.namespace.root="
			//If found, return number after that
			//Else keep looking
			if strings.Contains(body, "v23.namespace.root=") {
				//formatting return string
				namespaces := strings.SplitAfter(body, "v23.namespace.root=")
				for i := 1; i < len(namespaces); i += 2 {
					namespaceWithJunk := namespaces[i]
					namespace := strings.SplitAfter(namespaceWithJunk, "\n")[0]
					cleanNamespace := strings.TrimSpace(namespace)
					if cleanNamespace != "" {
						return cleanNamespace, nil
					}
				}
			}
		}
	}
	//no instance of "v23.namespace.root=" is found
	return "", errors.New("No namespace found")
}
