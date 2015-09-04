package discovery


import (
	"testing"
)

//Testing a valid site with a valid namespace
func TestOne(t *testing.T) {
  	expect := "104.197.96.113:3389"
  	host := "http://trustybike.net"
  	ns, err := FindNamespace(host)
  	if ns != expect {
		t.Errorf("Expected \"%s\", got \"%s\" and error \"%s\"", expect, ns, err)
  	}
}

//Testing an invalid site
func TestTwo(t *testing.T) {
	host := "not-a-website"
  	ns, err := FindNamespace(host)
  	if err == nil {
		t.Errorf("Expected error, got \"%s\" and no error", ns)
  	}
}

//Testing a valid site with no namespace
func TestThree(t *testing.T) {
	host := "http://www.facebook.com"
  	ns, err := FindNamespace(host)
  	if err == nil {
		t.Errorf("Expected error, got \"%s\" and no error", ns)
  	}
}