#!/bin/bash
cd /Users/zhiwang/diraclang/dirac-flow/examples
echo "Sending message..."
node /Users/zhiwang/diraclang/dirac/dist/cli.js test-queue-send.di
echo "Message sent!"
