:: this processes %1 swf into %2 and then replaces %1 with %2
:: make sure tdsi.bat is in the path; if you have 7z installed, remove -D key
cmd /c tdsi.bat -i %1 -o %2 -Dapparat.7z.enabled=false
del %1
copy %2 %1
del %2