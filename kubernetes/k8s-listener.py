import httplib
import requests
import sys
import simplejson

def hook(r, *args, **kwargs):
    print r

url = 'http://localhost:8080/apis/romana3.io/demo/v1/namespaces/default/networkpolicys/?watch=true'

def process(s):
    obj = simplejson.loads(s)
    op = obj["type"]
    details = obj["object"]["spec"]
    if op == 'ADDED':
        print "Added: %s" % details
    elif op == 'DELETED':
        print "Deleted: %s" % details
    else:
        print "Unknown operation: %s" % op

def main():
    r = requests.get(url, stream=True)
    iter = r.iter_content(1)
    while True:
        len_buf = ""
        while True:
            c = iter.next()
            if c == "\r":
                c2 = iter.next()
                if c2 != "\n":
                    raise "Unexpected %c after \\r" % c2
                break
            else:
                len_buf += c
        len = int(len_buf, 16)
        #        print "Chunk %s" % len
        buf = ""
        for i in range(len):
            buf += iter.next()
        process(buf)
        c = iter.next()
        c2 = iter.next()
        if c != '\r' or c2 != '\n':
            raise "Expected CRLF, got %c%c" % (c, c2)


if __name__ == "__main__":
    main()
