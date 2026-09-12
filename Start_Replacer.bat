@echo off
echo Starting local server for Batch Code Replacer...
start http://127.0.0.1:8000/replacer.html
python -m http.server 8000