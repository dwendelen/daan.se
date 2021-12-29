package main

import (
	"bytes"
	"errors"
	"fmt"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/route53"
	"log"
	"net"
	"os"
	"time"
)

func main() {
	if len(os.Args) < 5 {
		fmt.Println("Usage dynv6 <interval> <mac> <zoneId> <domain>")
		return
	}

	duration, err := time.ParseDuration(os.Args[1])
	if err != nil {
		log.Fatal("Could not parse duration", err)
	}
	mac, err := net.ParseMAC(os.Args[2])
	if err != nil {
		log.Fatal("Could not parse mac address", err)
	}
	zoneId := os.Args[3]
	domain := os.Args[4]

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
			err := sendPrefix(zoneId, domain, ip)
			if err != nil {
				log.Println("Could not update ip, waiting an extra minute")
				log.Println(err)
				time.Sleep(1 * time.Minute)
			} else {
				lastSentIp = ip
			}
		}

		time.Sleep(duration)
	}
}

func sendPrefix(zoneId string, domain string, ip net.IP) error {
	mySession, err := session.NewSession()
	if err != nil {
		return err
	}
	client := route53.New(mySession)
	act := "UPSERT"
	ttl := int64(60)
	typ := route53.RRTypeAaaa
	val := ip.String()
	_, err = client.ChangeResourceRecordSets(&route53.ChangeResourceRecordSetsInput{
		HostedZoneId: &zoneId,
		ChangeBatch: &route53.ChangeBatch{
			Changes: []*route53.Change{{
				Action: &act,
				ResourceRecordSet: &route53.ResourceRecordSet{
					Name: &domain,
					TTL:  &ttl,
					Type: &typ,
					ResourceRecords: []*route53.ResourceRecord{{
						Value: &val,
					}},
				},
			}},
			Comment: nil,
		},
	})

	if err != nil {
		return err
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
