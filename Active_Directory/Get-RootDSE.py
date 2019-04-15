import ldap, argparse, json

# Built by Liam Glanfield @OneLogicalMyth

class RootDSE:

        def __init__(self, dc):
                self.dc = dc
                self.b = ""
                self.s = ldap.SCOPE_BASE
                self.a = None
                self.f = "objectclass=*"

        def connect(self):
                try:
                        self.l = ldap.open(self.dc)
                except ldap.LDAPError, e:
                        print e

        def getRootDSEraw(self):
                try:
                        ldap_result_id = self.l.search(self.b, self.s, self.f, self.a)
                        result_type, result_data = self.l.result(ldap_result_id, 0)
                        if result_type == ldap.RES_SEARCH_ENTRY:
                                return result_data[0][1]
                        else:
                                print "No result"
                except ldap.LDAPError, e:
                        print e

        def getFL(self,numeric):
                functions = {
                                "0": "2000",
                                "1": "2003 Interim",
                                "2": "2003",
                                "3": "2008",
                                "4": "2008 R2",
                                "5": "2012",
                                "6": "2012 R2",
                                "7": "2016"}
                return functions[numeric]

        def getRootDSE(self):
                rootdse = self.getRootDSEraw()
                output = {
                                "DNSHostName": rootdse["dnsHostName"][0],
                                "HostSiteDN": rootdse["serverName"][0],
                                "DomainDN": rootdse["rootDomainNamingContext"][0],
                                "HostOS": self.getFL(rootdse["domainControllerFunctionality"][0]),
                                "HostCurrentTime": rootdse["currentTime"][0],
                                "DomainFunctionalLevel": self.getFL(rootdse["domainFunctionality"][0]),
                                "ForestFunctionalLevel": self.getFL(rootdse["forestFunctionality"][0]),
                                "Sychronized": rootdse["isSynchronized"][0],
                                "GlobalCatalog": rootdse["isGlobalCatalogReady"][0]
                        }

                return output

if __name__ == "__main__":

        # parse arguments and run script
        parser = argparse.ArgumentParser(description='Grabs info from RootDSE, no auth requried.')
        parser.add_argument('--dc', type=str, help='The domain controller IP or hostname.')
        parser.add_argument('--json', action='store_true', help='Output to JSON.')
        args = parser.parse_args()

        if args.dc:
                r = RootDSE(args.dc)
                r.connect()
                rootdse = r.getRootDSE()
                if args.json:
                        print json.dumps(rootdse, indent=4)
                else:
                        print "DNSHostName: " + rootdse["DNSHostName"]
                        print "HostSiteDN: " + rootdse["HostSiteDN"]
                        print "DomainDN: " + rootdse["DomainDN"]
                        print "HostOS: " + rootdse["HostOS"]
                        print "HostCurrentTime: " + rootdse["HostCurrentTime"]
                        print "DomainFunctionalLevel: " + rootdse["DomainFunctionalLevel"]
                        print "ForestFunctionalLevel: " + rootdse["ForestFunctionalLevel"]
                        print "Sychronized: " + rootdse["Sychronized"]
                        print "GlobalCatalog: " + rootdse["GlobalCatalog"]
