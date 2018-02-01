#!/usr/bin/python
#### written by xychix, https://github.com/xychix/
#
# This script requires some explanation, basically this loads a policy, alters it by adding a nmap file and then runs it
# in order to be able to import nmap_xml files you do need the proper plugin for that,
# it can be found here: https://discussions.tenable.com/docs/DOC-1269
# nasl is here: https://static.tenable.com/documentation/nmapxml.nasl 
#
# follow the instructions to install the nmap_xml_importer to your nessus install
#
# for this example I've ran 
#    nmap -oX t1.xml 192.168.1.1/24
#    nessus_nmapxml.py -f t1.xml -u admin -p MYPASSWORD -n t7_python
#
#
# documentation: Nmap and Nessus 6.4.2
# https://discussions.tenable.com/docs/DOC-1269

#imports for main
import argparse
from datetime import datetime
import getpass
#imports for parse_nmapxml
import xml.etree.ElementTree as etree
#imports for nessrest
import sys
sys.path.append('../')
from nessrest import ness6rest

def parse_nmapxml(filename):
    # this function will give you all the ip's from the several hosts in the nmap xml
    mainTree = etree.parse(filename)
    nmaprun = mainTree.getroot()
    hosts = nmaprun.findall('host')
    targets = []
    for host in hosts:
        address = host.find('address')
        targets.append(address.attrib['addr'])
    return(targets)

def startscan(args):
    scan = ness6rest.Scanner(url=args['hosturl'],login=args['user'],password=args['password'], insecure=True)
    targets = parse_nmapxml(args['filename'])
    scan.upload(args['filename'])
    filename = scan.res[u'fileuploaded']
    scan.policy_exists(args['policy'])
    scan.policy_set(args['policy'])
    settings = {"settings": {}}
    settings["settings"].update({"import_nmap_xml":"yes"}) 
    settings["settings"].update({"import_nmap_xml_file":filename})
    scan.action(action="policies/" + str(scan.policy_id), method="put",extra=settings)
    scan.policy_set(args['policy'])
    t = ','
    targets = t.join(parse_nmapxml(args['filename']))
    print targets
    scan.scan_add(targets=targets,name=args['scanname'])
    scan.scan_run()

def main():
    parser = argparse.ArgumentParser(description='Description of your program')
    parser.add_argument('-f','--filename', help='file generated with nmap -oX', required=True)
    parser.add_argument('-H','--hosturl', help='hosturl for logging in to nessus server', default="https://127.0.0.1:8834")
    parser.add_argument('-n','--scanname', help='name for the scan in nessus, default is nmap_xml_<date>', required=False)
    parser.add_argument('-P','--policy', help='Nessus policy that is prepared with script_id(33818) Nmap (XML file importer)', default="nmap_xml")
    parser.add_argument('-p','--password', help='password for logging in to nessus server', required=False)
    parser.add_argument('-u','--user', help='username for logging in to nessus server', required=False)
    
    args = vars(parser.parse_args())
    
    print args
    
    if not args['hosturl']:
        args['hosturl'] = getpass._raw_input('Hosturl: ')
    if not args['user']:
        args['user'] = getpass._raw_input('User: ')
    if not args['password']:
        args['password'] = getpass.getpass()
    if not args['scanname']:
        args['scanname'] = "nmap_xml_%s"%datetime.now().strftime("%Y%m%d-%H%M%S")
    print args
    startscan(args)

if __name__ == "__main__":
    main()
