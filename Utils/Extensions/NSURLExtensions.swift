/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

private struct ETLDEntry: Printable {
    let entry: String

    var isNormal: Bool { return isWild || !isException }
    var isWild: Bool = false
    var isException: Bool = false

    init(entry: String) {
        self.entry = entry
        self.isWild = entry.hasPrefix("*")
        self.isException = entry.hasPrefix("!")
    }

    private var description: String {
        return "{ Entry: \(entry), isWildcard: \(isWild), isException: \(isException) }"
    }
}

private typealias TLDEntryMap = [String:ETLDEntry]

private func loadEntriesFromDisk() -> TLDEntryMap? {
    if let data = NSString.contentsOfFileWithResourceName("effective_tld_names", ofType: "dat", fromBundle: NSBundle(identifier: "org.mozilla.Shared")!, encoding: NSUTF8StringEncoding, error: nil) {
        var lines = data.componentsSeparatedByString("\n") as! [String]
        var trimmedLines = filter(lines) { !$0.hasPrefix("//") && $0 != "\n" && $0 != "" }

        var entries = TLDEntryMap()
        for line in trimmedLines {
            let entry = ETLDEntry(entry: line)
            let key: String
            if entry.isWild {
                // Trim off the '*.' part of the line
                key = line.substringFromIndex(advance(line.startIndex, 2))
            } else if entry.isException {
                // Trim off the '!' part of the line
                key = line.substringFromIndex(advance(line.startIndex, 1))
            } else {
                key = line
            }
            entries[key] = entry
        }
        return entries
    }
    return nil
}

private var etldEntries: TLDEntryMap? = {
    return loadEntriesFromDisk()
}()

extension NSURL {
    public func withQueryParams(params: [NSURLQueryItem]) -> NSURL {
        let components = NSURLComponents(URL: self, resolvingAgainstBaseURL: false)!
        var items = (components.queryItems ?? [])
        for param in params {
            items.append(param)
        }
        components.queryItems = items
        return components.URL!
    }

    public func withQueryParam(name: String, value: String) -> NSURL {
        let components = NSURLComponents(URL: self, resolvingAgainstBaseURL: false)!
        let item = NSURLQueryItem(name: name, value: value)
        components.queryItems = (components.queryItems ?? []) + [item]
        return components.URL!
    }

    public func getQuery() -> [String: String] {
        var results = [String: String]()
        var keyValues = self.query?.componentsSeparatedByString("&")

        if keyValues?.count > 0 {
            for pair in keyValues! {
                let kv = pair.componentsSeparatedByString("=")
                if kv.count > 1 {
                    results[kv[0]] = kv[1]
                }
            }
        }

        return results
    }

    public var hostPort: String? {
        if let host = self.host {
            if let port = self.port?.intValue {
                return "\(host):\(port)"
            }
            return host
        }
        return nil
    }

    public func absoluteStringWithoutHTTPScheme() -> String? {
        if let urlString = self.absoluteString {
            // If it's basic http, strip out the string but leave anything else in
            if urlString.hasPrefix("http://") ?? false {
                return urlString.substringFromIndex(advance(urlString.startIndex, 7))
            } else {
                return urlString
            }
        } else {
            return nil
        }
    }

    /**
    Returns the base domain from a given hostname. The base domain name is defined as the public domain suffix
    with the base private domain attached to the front. For example, for the URL www.bbc.co.uk, the base domain
    would be bbc.co.uk. The base domain includes the public suffix (co.uk) + one level down (bbc).

    :returns: The base domain string for the given host name.
    */
    public func baseDomain() -> String? {
        if let host = self.host {
            return publicSuffixFromHost(host, withAdditionalParts: 1)
        } else {
            return nil
        }
    }

    /**
    Returns the public portion of the host name determined by the public suffix list found here: https://publicsuffix.org/list/. 
    For example for the url www.bbc.co.uk, based on the entries in the TLD list, the public suffix would return co.uk.

    :returns: The public suffix for within the given hostname.
    */
    public func publicSuffix() -> String? {
        if let host = self.host {
            return publicSuffixFromHost(host, withAdditionalParts: 0)
        } else {
            return nil
        }
    }
}

//MARK: Private Helpers
private extension NSURL {
    private func publicSuffixFromHost(var host: String, withAdditionalParts additionalPartCount: Int) -> String? {
        if host.isEmpty { return nil }

        // Check edge cast where host is either a single or double .
        if host.isEmpty || host.lastPathComponent == "." { return "" }

        /**
        *  The following algorithm breaks apart the domain and checks each sub domain against the effective TLD
        *  entries from the effective_tld_names.dat file. It works like this:
        *
        *  Example Domain: test.bbc.co.uk
        *  TLD Entry: bbc
        *
        *  1. Start off by checking the current domain (test.bbc.co.uk)
        *  2. Also store the domain after the next dot (bbc.co.uk)
        *  3. If we find an entry that matches the current domain (test.bbc.co.uk), perform the following checks:
        *    i. If the domain is a wildcard AND the previous entry is not nil, then the current domain matches
        *       since it satisfies the wildcard requirement.
        *    ii. If the domain is normal (no wildcard) and we don't have anything after the next dot, then
        *        currentDomain is a valid TLD
        *    iii. If the entry we matched is an exception case, then the base domain is the part after the next dot
        *
        *  On the next run through the loop, we set the new domain to check as the part after the next dot,
        *  update the next dot reference to be the string after the new next dot, and check the TLD entries again.
        *  If we reach the end of the host (nextDot = nil) and we haven't found anything, then we've hit the 
        *  top domain level so we use it by default.
        */

        let tokens = host.componentsSeparatedByString(".")
        let tokenCount = count(tokens)
        var suffix: String?
        var previousDomain: String? = nil
        var currentDomain: String = host

        for offset in 0..<tokenCount {
            // Store the offset for use outside of this scope so we can add additional parts if needed
            let nextDot: String? = offset + 1 < tokenCount ? join(".", tokens[offset + 1..<tokenCount]) : nil

            if let entry = etldEntries?[currentDomain] {
                if entry.isWild && (previousDomain != nil) {
                    suffix = previousDomain
                    break;
                } else if entry.isNormal || (nextDot == nil) {
                    suffix = currentDomain
                    break;
                } else if entry.isException {
                    suffix = nextDot
                    break;
                }
            }

            previousDomain = currentDomain
            if let nextDot = nextDot {
                currentDomain = nextDot
            } else {
                break
            }
        }

        var baseDomain: String?
        if additionalPartCount > 0 {
            if let suffix = suffix {
                // Take out the public suffixed and add in the additional parts we want
                let suffixlessHost = host.stringByReplacingOccurrencesOfString(suffix, withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
                let suffixlessTokens = suffixlessHost.componentsSeparatedByString(".").filter { $0 != "" }
                let maxAdditionalCount = max(0, suffixlessTokens.count - additionalPartCount)
                let additionalParts = suffixlessTokens[maxAdditionalCount..<suffixlessTokens.count]
                let partsString = join(".", additionalParts)
                baseDomain = join(".", [partsString, suffix])
            } else {
                return nil
            }
        } else {
            baseDomain = suffix
        }

        return baseDomain
    }
}
