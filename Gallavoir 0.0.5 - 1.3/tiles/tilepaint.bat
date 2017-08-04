@echo off
setlocal

(
  for %%f in (*.png) do (
   tilerecolor.bat %%f "#d7d7d7" "#aaaaaa" "#868686" "#545454"
  )
)
## ^ brightest to darkest.