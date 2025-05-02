#!/bin/bash

echo " Cleaning build..."
xcodebuild clean -scheme BoilerBuzz -sdk iphonesimulator -derivedDataPath ./build

echo " Building app..."
xcodebuild -scheme BoilerBuzz -sdk iphonesimulator -derivedDataPath ./build

echo " Uninstalling old app..."
xcrun simctl uninstall booted com.Patrick.BoilerBuzz

echo " Installing new app..."
xcrun simctl install booted ./build/Build/Products/Debug-iphonesimulator/BoilerBuzz.app

echo " Launching app..."
xcrun simctl launch booted com.Patrick.BoilerBuzz

