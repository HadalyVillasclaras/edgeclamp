#!/bin/bash
set -e

swiftc Sources/EdgeClamp/*.swift -o EdgeClamp
echo "Built EdgeClamp"