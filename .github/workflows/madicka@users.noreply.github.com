# This workflow integrates SecurityCodeScan with GitHub's Code Scanning feature
# SecurityCodeScan is a vulnerability patterns detector for C# and VB.NET

name: SecurityCodeScan

on:
  push:
    branches: [ main ]
  pull_request:
    # The branches below must be a subset of the branches above
    branches: [ main ]
  schedule:
    - cron: '19 0 * * 2'

jobs:
  SCS:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v2
      - uses: nuget/setup-nuget@v1.0.5
      - uses: microsoft/setup-msbuild@v1.0.2
      
      - name: Set up projects for analysis
        uses: security-code-scan/security-code-scan-add-action@main
        
      - name: Restore dependencies	
        run: dotnet restore

      - name: Build
        run: dotnet build --no-restore

      - name: Convert sarif for uploading to GitHub
        uses: security-code-scan/security-code-scan-results-action@main

      - name: Upload sarif
        uses: github/codeql-action/upload-sarif@v1
