package main

import (
	"bytes"
	"errors"
	"fmt"
	"io/ioutil"
	"log"
	"net"
	"net/http"
	"os"
	"strings"
	"time"
)

func main() {
	if len(os.Args) == 1 {
		fmt.Println("Usage dynv6 <interval> <path-to-file-with-token> <mac> <zone>")
	}

	duration, err := time.ParseDuration(os.Args[1])
	if err != nil {
		log.Fatal("Could not parse duration", err)
	}
	tokenAsBytes, err := ioutil.ReadFile(os.Args[2])
	if err != nil {
		log.Fatal("Could not open token file", err)
	}
	token := strings.TrimSpace(string(tokenAsBytes))
	mac, err := net.ParseMAC(os.Args[3])
	if err != nil {
		log.Fatal("Could not parse mac address", err)
	}
	zone := os.Args[4]

	var lastSentIp net.IP = nil
	for {
		fmt.Println("Polling")
		ip, err := findPrefix(mac)
		if err != nil {
			log.Println("Could not find current ip:", err.Error())
			continue
		}

		if !bytes.Equal(ip, lastSentIp) {
			fmt.Println("Sending new IP. New:", ip, "Old:", lastSentIp)
			err := sendPrefix(zone, token, ip)
			if err != nil {
				log.Println("Could not update ip, waiting an extra minute")
				time.Sleep(1 * time.Minute)
			} else {
				lastSentIp = ip
			}
		}

		time.Sleep(duration)
	}
}

func sendPrefix(zone string, token string, ip net.IP) error {
	url := fmt.Sprint("https://dynv6.com/api/update?zone=", zone, "&token=", token, "&ipv6=", ip)
	response, err := http.Get(url)
	if err != nil {
		return err
	}
	if response.StatusCode != 200 {
		msg := fmt.Sprint("Wrong return code. Expected: 200, got: ", response.StatusCode)
		return errors.New(msg)
	}
	return nil
}

func findPrefix(mac net.HardwareAddr) (net.IP, error) {
	interfaces, err := net.Interfaces()
	if err != nil {
		return nil, err
	}

InterfaceLoop:
	for _, iface := range interfaces {
		if !bytes.Equal(mac, iface.HardwareAddr) {
			continue InterfaceLoop
		}
		addrs, err := iface.Addrs()
		if err != nil {
			return nil, err
		}

	AddressLoop:
		for _, addr := range addrs {
			var ip net.IP
			switch v := addr.(type) {
			case *net.IPNet:
				ip = v.IP
			case *net.IPAddr:
				ip = v.IP
			default:
				continue AddressLoop
			}

			if ip.To4() != nil || !ip.IsGlobalUnicast() {
				continue AddressLoop
			}

			return ip, nil
		}
	}

	return nil, errors.New("no ip found")
}
