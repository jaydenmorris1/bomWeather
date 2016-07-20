'Version 0.1m

Option Explicit

Dim observation_url, forecast_url, forecast_station, log_file, observation_file, forecast_file, observation_station, ItemCount, wTempDir, wAppDir, Shell
Dim ForecastCity, ObservationType, Skin, contents, Item, parsed_data (), SunRiseLocation, State, TimeZone, wbomDetails
Dim wshShell, ProxyServer, ProxyPort, ProxyUsername, ProxyPassword, UseProxy, DayLightSavings, ActiveTimeBias, TimeBias, Day0, wTemp, MoonPhases
Const ForReading = 1, ForWriting = 2, ForAppending = 8
Const ApplicationFolder = "Rainmeter-kanine"

Dim Debug, FileTracking, GenerateMeasureSection
Debug = False
FileTracking = False
GenerateMeasureSection = False

Set shell = WScript.CreateObject( "WScript.Shell" )
wAppDir = (shell.ExpandEnvironmentStrings("%APPDATA%")) & "\"& ApplicationFolder
wTempDir = (shell.ExpandEnvironmentStrings("%TEMP%")) & "\"& ApplicationFolder
Set Shell = Nothing

'Choose your skin folder here, images should be in @Resources\bomweather\yourskin
Skin="KonfabulatorPLUS"

' Settings below are static so should not need to be changed
observation_file = "bomWeatherObservation"
forecast_file = "bomWeatherForecast"
Itemcount = 0

Private Function Get_Cache_Value (paramString, statfile)
  
  Dim fs, fp, f, fl, counter, InTime, wParam

  InTime = Now()
  wParam = LCase(Replace(paramString," ",""))

  Set fs = CreateObject ("Scripting.FileSystemObject")

  If (fs.FileExists (wTempDir & "/" & statfile & ".txt")) Then
	
    Set f = fs.OpenTextFile (wTempDir & "/" & statfile & ".txt", ForReading)
    contents = f.readall
    f.Close
    
    If InStr(contents,"</EndofFile>") > 0 Then
      item = parse_item (contents, "<" & wParam & ">", "</" & wParam & ">")
    Else
      item = "Bad Read"
    End If
 
    'If FileTracking Then
    '  Set f = fs.OpenTextFile(log_file & "-" & replace(paramString," ","-") & ".log", ForAppending,True,0)
    '  f.writeline Now() & " " & statfile & " - InTime : " & InTime & " Result > " & Item & " Duration: " & Round((Now() - InTime)*24*60*60,2) & "s"
    '  f.close
    'End If
    
    Set fs = Nothing
		
    contents = item

  Else
    contents = "Missing Update File - Check Updating Meter"
  End If

  Get_Cache_Value = contents

End Function

Private Function FormatCalc (paramString, wMeasure)

  wRegExp = wRegExp & "<" & paramString & ">(.*)" & "</" & paramString & ">.*"
  
  wMeasureDefs = wMeasureDefs & "[Measure" & paramString & "]" & vbCRLF
  wMeasureDefs = wMeasureDefs & "Measure=Plugin" & vbCRLF
  wMeasureDefs = wMeasureDefs & "Plugin=Plugins\WebParser.dll" & vbCRLF
  wMeasureDefs = wMeasureDefs & "Url=[MeasurebomWeather]" & vbCRLF
  wMeasureDefs = wMeasureDefs & "StringIndex=" & wMeasureIdx & vbCRLF
  wMeasureDefs = wMeasureDefs & vbCRLF
  wMeasureIdx = wMeasureIdx + 1

  FormatCalc = "<" & paramString & ">" & wMeasure & "</" & paramString & ">"

End Function


Private Function ConvertDate (paramString)

ConvertDate = Mid(ParamString,7,2) & "/" & Mid(ParamString,5,2) & "/" & Mid(ParamString,1,4) & " " & _
              Mid(ParamString,10,2) & ":" & Mid(ParamString,12,2)
End Function

Private Function ConvertDetObsDate (paramString)

  Dim OffSet, tmpDay, tmpDate, tmpFormDate, tmpTime
  
  tmpDate = Now()

  tmpDay = CInt(Left(paramstring,InStr(paramstring,"/")-1))
  
  If tmpDay < Day(tmpDate) and tmpDay = 1 Then TmpDate = TmpDate + 1
  If tmpDay < Day(tmpDate) Then TmpDate = TmpDate - 1
  If tmpDay > Day(tmpDate) Then TmpDate = TmpDate + 1
  
  tmpFormDate = Right("0" & Day(tmpDate),2) & "/" & Right("0" & Month(tmpDate),2) & "/" & Year(tmpDate)

  tmpTime = CDate(Mid(paramstring,InStr(paramstring,"/")+1))
  
  tmpFormDate = tmpFormDate & " " & Right("0" & Hour(tmpTime),2) & ":" & Right("0" & Minute(tmpTime),2)
  
  ConvertDetObsDate = tmpFormDate
  
End Function

Private Function ConvertDetObsTime (paramString)

  Dim tmpTime
 
   If IsDate(Mid(paramstring,InStr(paramstring,"/")+1)) Then
   	 tmpTime = CDate(Mid(paramstring,InStr(paramstring,"/")+1))
   Else
     tmpTime = CDate("00:00am")
   End If
 
  ConvertDetObsTime = Right("0" & Hour(tmpTime),2) & Right("0" & Minute(tmpTime),2) & Right("0" & Second(tmpTime),2) 
  
End Function

Private Function Floor(byval n)
	Dim iTmp
	n = cdbl(n)
	iTmp = Round(n)
	if iTmp > n then iTmp = iTmp - 1
	Floor = cInt(iTmp)
End Function

Private Function Ceiling(byval n)
	Dim iTmp, f
	n = cdbl(n)
	f = Floor(n)
	if f = n then
		Ceiling = n
		Exit Function
	End If
	Ceiling = cInt(f + 1)
End Function

Private Function NowText()

  Dim CurrentTime

  CurrentTime = Now()

  If Hour(CurrentTime) <  10 and Minute(CurrentTime) <  10 Then NowText = "0" & Hour(CurrentTime) & ":0" & Minute(CurrentTime)
  If Hour(CurrentTime) >= 10 and Minute(CurrentTime) <  10 Then NowText =       Hour(CurrentTime) & ":0" & Minute(CurrentTime)
  If Hour(CurrentTime) <  10 and Minute(CurrentTime) >= 10 Then NowText = "0" & Hour(CurrentTime) & ":"  & Minute(CurrentTime)
  If Hour(CurrentTime) >= 10 and Minute(CurrentTime) >= 10 Then NowText =       Hour(CurrentTime) & ":"  & Minute(CurrentTime)

End Function

Function Station_Updated ()

	Station_Updated = Get_Cache_Value("Station Update", observation_file)

End Function

Function Station_Updated_Time ()

	Station_Updated_Time = Mid(Get_Cache_Value("Station Update", observation_file),12)

End Function

Function Station_Name ()

	Station_Name = Get_Cache_Value("Station Name", observation_file)

End Function

Function Station_At ()

	Station_At = Station_Name() & " at " & Station_Updated_Time()

End Function

Function Current_Temp ()

	Current_Temp = Get_Cache_Value("Current Temp", observation_file) & "°"

End Function

Function App_Temp ()

	App_Temp = Get_Cache_Value("App Temp", observation_file) & "°"

End Function

Function DeltaT ()

	DeltaT = Get_Cache_Value("Delta-T", observation_file)

End Function

Function Current_Temp_Numeric ()

	Current_Temp_Numeric = Get_Cache_Value("Current Temp", observation_file)

End Function

Function Current_Rel_Humidity ()

  Current_Rel_Humidity  = Get_Cache_Value("Relative Humidity", observation_file)

End Function

Function Current_Dew_Point ()

  Current_Dew_Point  = Get_Cache_Value("Dew Point", observation_file)

End Function

Function Current_Pressure ()

  Current_Pressure  = Get_Cache_Value("Pressure hPa", observation_file)

End Function

Function Current_RainFall ()

  Current_RainFall  = Get_Cache_Value("Rain Since 9am mm", observation_file)

End Function

Function Current_WindDirSpeed ()

  Current_WindDirSpeed  = Get_Cache_Value("Wind Direction", observation_file) & " " & _
                          Get_Cache_Value("Wind Speed km", observation_file) & "/" & _
                          Get_Cache_Value("Wind Gust km", observation_file) & " kmh"

End Function

Function Observed_MinTempTime ()

  Observed_MinTempTime  = Get_Cache_Value("Extreme Min", observation_file) & "° @ " & _
                          Mid(Get_Cache_Value("Extreme Min Time", observation_file),10,2) & ":" & _
                          Mid(Get_Cache_Value("Extreme Min Time", observation_file),12,2)
End Function

Function Observed_MaxTemp ()

  Observed_MaxTemp  = Get_Cache_Value("Extreme Max", observation_file) & "°"

End Function

Function Observed_MaxTime ()

  Observed_MaxTime  = Mid(Get_Cache_Value("Extreme Max Time", observation_file),10,2) & ":" & _
                      Mid(Get_Cache_Value("Extreme Max Time", observation_file),12,2)
End Function

Function Observed_MaxTempTime ()

  Observed_MaxTempTime  = Observed_MaxTemp () & " @ " & Observed_MaxTime()

End Function

Function Current_Forecast_Text ()

  Current_Forecast_Text  = Get_Cache_Value("Forecast Day 0 Text", forecast_file) 

End Function

Function Current_Forecast_Day ()

  Current_Forecast_Day  = Get_Cache_Value("Forecast Day 0", forecast_file) 

End Function

Function Current_Forecast_Min ()

  Current_Forecast_Min = Get_Cache_Value("Forecast Day 0 Min", forecast_file)

End Function

Function Current_Forecast_Max ()

  Current_Forecast_Max = Get_Cache_Value("Forecast Day 0 Max", forecast_file)

End Function

Function Current_Forecast_MinMax ()

  If Get_Cache_Value("Forecast Day 0 Min", forecast_file) = "" AND _
     Get_Cache_Value("Forecast Day 0 Max", forecast_file) <> "" Then
  	Current_Forecast_MinMax = "Max " & Get_Cache_Value("Forecast Day 0 Max", forecast_file) & "°"
  Else
    If Get_Cache_Value("Forecast Day 0 Max", forecast_file) = "" Then
      Current_Forecast_MinMax  = ""
    Else
      Current_Forecast_MinMax  = Get_Cache_Value("Forecast Day 0 Max", forecast_file) & "°/" & _
                               Get_Cache_Value("Forecast Day 0 Min", forecast_file)&"°"
    End If
  End If

End Function

Function Current_Forecast_ShortText ()

  Current_Forecast_ShortText  = Trim(Current_Forecast_Day () & " " & Current_Forecast_MinMax ())

End Function

Function Day_1_Name ()

  Day_1_Name  = Get_Cache_Value("Forecast Day 1", forecast_file)
                   
End Function

Function Day_1_ShortCapName ()

  Day_1_ShortCapName  = UCase(Mid(Get_Cache_Value("Forecast Day 1", forecast_file),1,3))
                   
End Function

Function Day_1_Forecast ()

  Day_1_Forecast = Get_Cache_Value("Forecast Day 1 Text", forecast_file)
                   
End Function

Function Day_1_HighLow ()

  Day_1_HighLow  = Get_Cache_Value("Forecast Day 1 Max", forecast_file) & "°" & "/" & _
                   Get_Cache_Value("Forecast Day 1 Min", forecast_file) & "°"
                   
End Function

Function Day_2_Name ()

  Day_2_Name  = Get_Cache_Value("Forecast Day 2", forecast_file)
                   
End Function

Function Day_2_ShortCapName ()

  Day_2_ShortCapName  = UCase(Mid(Get_Cache_Value("Forecast Day 2", forecast_file),1,3))
                   
End Function

Function Day_2_Forecast ()

  Day_2_Forecast = Get_Cache_Value("Forecast Day 2 Text", forecast_file)
                   
End Function

Function Day_2_HighLow ()

  Day_2_HighLow  = Get_Cache_Value("Forecast Day 2 Max", forecast_file) & "°" & "/" & _
                   Get_Cache_Value("Forecast Day 2 Min", forecast_file) & "°" 
                   
End Function

Function Day_3_Name ()

  Day_3_Name  = Get_Cache_Value("Forecast Day 3", forecast_file)
                   
End Function

Function Day_3_ShortCapName ()

  Day_3_ShortCapName  = UCase(Mid(Get_Cache_Value("Forecast Day 3", forecast_file),1,3))
                   
End Function

Function Day_3_Forecast ()

  Day_3_Forecast = Get_Cache_Value("Forecast Day 3 Text", forecast_file)
                   
End Function

Function Day_3_HighLow ()

  Day_3_HighLow  = Get_Cache_Value("Forecast Day 3 Max", forecast_file) & "°" & "/" & _
                   Get_Cache_Value("Forecast Day 3 Min", forecast_file) & "°" 
                   
End Function

Function Day_4_Name ()

  Day_4_Name  = Get_Cache_Value("Forecast Day 4", forecast_file)
                   
End Function

Function Day_4_ShortCapName ()

  Day_4_ShortCapName  = UCase(Mid(Get_Cache_Value("Forecast Day 4", forecast_file),1,3))
                   
End Function

Function Day_4_Forecast ()

  Day_4_Forecast = Get_Cache_Value("Forecast Day 4 Text", forecast_file)
                   
End Function

Function Day_4_HighLow ()

  Day_4_HighLow  = Get_Cache_Value("Forecast Day 4 Max", forecast_file) & "°" & "/" & _
                   Get_Cache_Value("Forecast Day 4 Min", forecast_file) & "°" 
                   
End Function

Function Day_5_Name ()

  Day_5_Name  = Get_Cache_Value("Forecast Day 5", forecast_file)
                   
End Function

Function Day_5_ShortCapName ()

  Day_5_ShortCapName  = UCase(Mid(Get_Cache_Value("Forecast Day 5", forecast_file),1,3))
                   
End Function

Function Day_5_Forecast ()

  Day_5_Forecast = Get_Cache_Value("Forecast Day 5 Text", forecast_file)
                   
End Function

Function Day_5_HighLow ()

  Day_5_HighLow  = Get_Cache_Value("Forecast Day 5 Max", forecast_file) & "°" & "/" & _
                   Get_Cache_Value("Forecast Day 5 Min", forecast_file) & "°"
                   
End Function

Function Day_6_Name ()

  Day_6_Name  = Get_Cache_Value("Forecast Day 6", forecast_file)
                   
End Function

Function Day_6_ShortCapName ()

  Day_6_ShortCapName  = UCase(Mid(Get_Cache_Value("Forecast Day 6", forecast_file),1,3))
                   
End Function

Function Day_6_Forecast ()

  Day_6_Forecast = Get_Cache_Value("Forecast Day 6 Text", forecast_file)
                   
End Function

Function Day_6_HighLow ()

  Day_6_HighLow  = Get_Cache_Value("Forecast Day 6 Max", forecast_file) & "°" & "/" & _
                   Get_Cache_Value("Forecast Day 6 Min", forecast_file) & "°"
                   
End Function

Function Trend_Days ()

  Trend_Days = Get_Cache_Value("Forecast Trend Days", forecast_file)
                   
End Function

Function Trend_ShortCapName ()

  Trend_ShortCapName  = "TREND"
                   
End Function

Function Trend_Forecast ()

  Trend_Forecast = Get_Cache_Value("Forecast Trend Text", forecast_file)
                   
End Function

Function Trend_Forecast_Min ()

  Trend_Forecast_Min = Get_Cache_Value("Forecast Trend Min", forecast_file)
                   
End Function

Function Trend_Forecast_Max ()

  Trend_Forecast_Max = Get_Cache_Value("Forecast Trend Max", forecast_file)
                   
End Function

Function Trend_HighLow ()

  Trend_HighLow = Get_Cache_Value("Forecast Trend Max", forecast_file) & "°" & "/" & _
                  Get_Cache_Value("Forecast Trend Min", forecast_file) & "°" 

End Function

Function Forecast_All_Text ()

  Forecast_All_Text = Get_Cache_Value("Forecast Day 0", forecast_file) & ": " & Get_Cache_Value("Forecast Day 0 Text", forecast_file) & ", " & _
                      Get_Cache_Value("Forecast Day 1", forecast_file) & ": " & Get_Cache_Value("Forecast Day 1 Text", forecast_file) & ", " & _
                      Get_Cache_Value("Forecast Day 2", forecast_file) & ": " & Get_Cache_Value("Forecast Day 2 Text", forecast_file) & ", " & _
                      Get_Cache_Value("Forecast Day 3", forecast_file) & ": " & Get_Cache_Value("Forecast Day 3 Text", forecast_file)
                   
End Function

Function Sunrise_Day0 ()

  Sunrise_Day0 = Get_Cache_Value("Day 0 SunRise", forecast_file)
                   
End Function

Function SunSet_Day0 ()

  SunSet_Day0 = Get_Cache_Value("Day 0 SunSet", forecast_file)
                   
End Function

Function Sunrise_Day1 ()

  Sunrise_Day1 = Get_Cache_Value("Day 1 SunRise", forecast_file)
                   
End Function

Function SunSet_Day1 ()

  SunSet_Day1 = Get_Cache_Value("Day 1 SunSet", forecast_file)
                   
End Function

Function NextSunrise ()

  Dim Currently
  
  Currently = NowText

  If Sunrise_Day0 > Currently Then 
  	NextSunrise = Sunrise_Day0
  Else
  	NextSunrise = Sunrise_Day1 & "+"
  End If  

End Function

Function NextSunset ()

  Dim Currently
  
  Currently = NowText

  If Sunset_Day0 > Currently Then 
  	NextSunset = Sunset_Day0
  Else
  	NextSunset = Sunset_Day1 & "+"
  End If  

End Function

Function Moonrise_Day0 ()

  Moonrise_Day0 = Get_Cache_Value("Day 0 MoonRise", forecast_file)
                   
End Function

Function MoonSet_Day0 ()

  MoonSet_Day0 = Get_Cache_Value("Day 0 MoonSet", forecast_file)
                   
End Function

Function Moonrise_Day1 ()

  Moonrise_Day1 = Get_Cache_Value("Day 1 MoonRise", forecast_file)
                   
End Function

Function MoonSet_Day1 ()

  MoonSet_Day1 = Get_Cache_Value("Day 1 MoonSet", forecast_file)
                   
End Function

Function NextMoonrise ()

  Dim Currently
  
  Currently = NowText

  If (Moonrise_Day0 > Currently) AND Moonrise_Day0 <> ":" Then  
  	NextMoonrise = Moonrise_Day0
  Else
  	NextMoonrise = Moonrise_Day1 & "+"
  End If  

End Function

Function NextMoonset ()

  Dim Currently
  
  Currently = NowText

  If (Moonset_Day0 > Currently) AND Moonset_Day0 <> ":" Then 
  	NextMoonset = Moonset_Day0
  Else
  	NextMoonset = Moonset_Day1 & "+"
  End If  

End Function

Function Tide_Day (DayNumber)

  Tide_Day = Get_Cache_Value("Tide Day " & DayNumber, forecast_file)
                   
End Function

Function Tide_Time (DayNumber, TimeNumber)

  If Get_Cache_Value("Tide Day " & DayNumber & " Time " & TimeNumber, forecast_file) <> "" Then
    Tide_Time = Get_Cache_Value("Tide Day " & DayNumber & " Time " & TimeNumber & " Type", forecast_file) & " " & _
                Get_Cache_Value("Tide Day " & DayNumber & " Time " & TimeNumber, forecast_file) & " " & _
                Get_Cache_Value("Tide Day " & DayNumber & " Time " & TimeNumber & " Height", forecast_file) &"m"
  Else
    Tide_Time = ""
  End If
                   
End Function

Function Update_Observation ()

  Dim xml, fs, f, UseProxy
 
  log_file = Observation_File

  Set fs = CreateObject ("Scripting.FileSystemObject")
  Set f = fs.CreateTextFile(log_file & "-Updating.txt", True)
  f.write "Updating Observation Data"
  f.close

  Randomize 'To try and avoid cached sites  

  Set xml = CreateObject("Microsoft.XMLHTTP")
  observation_url = observation_url & "?" & RND()*1000000000000000 

  On Error Resume Next

    If ProxyPassword <> "" Then
      xml.Open "POST", observation_url , False, ProxyUsername, ProxyPassword
    Else
      xml.Open "POST", observation_url , False, ProxyUsername, ProxyPassword
    End If
    xml.Send

    If  Err.Number <> 0 Then
      RaiseException "Poll Forecast Page Response - " & Forecast_url, Err.Number, Err.Description
    End If
    
  On Error GoTo 0

  Set f = fs.CreateTextFile (wTempDir & "/" & log_file & ".html", True)
  f.write (xml.responseText)
  f.close

  Set f = Nothing
  Set fs = Nothing
  Set xml = Nothing

  Update_Observation = parse_html("Observation")

End Function

Function Update_Forecast ()

  Dim xml, fs, f, UseProxy

  log_file = Forecast_File

  Set fs = CreateObject ("Scripting.FileSystemObject")

' TestingLine  If 1=2 Then 
  
    Set WshShell = CreateObject("WScript.Shell")

    DayLightSavings = WshShell.RegRead("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\TimeZoneInformation\DaylightBias")

    ActiveTimeBias = WshShell.RegRead("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\TimeZoneInformation\ActiveTimeBias")
    TimeBias = WshShell.RegRead("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\TimeZoneInformation\Bias")

    Set WshShell = Nothing

    Set xml = CreateObject("Microsoft.XMLHTTP")

    On Error Resume Next

      If ProxyPassword <> "" Then
        xml.Open "POST", Forecast_url, False, ProxyUsername, ProxyPassword
      Else
        xml.Open "POST", Forecast_url, False, ProxyUsername, ProxyPassword
      End If
      xml.Send
    
      If  Err.Number <> 0 Then
        RaiseException "Poll Forecast Page Response - " & Forecast_url, Err.Number, Err.Description
      End If
    
    On Error GoTo 0
        
    Set f = fs.CreateTextFile (log_file & "-Updating.txt", True)
    f.write "Updating Forecast Measures"
    f.close
    Set f = fs.CreateTextFile (wTempDir & "/" & log_file & ".html", True)
    f.write (xml.responseText)
    f.close
	
    Set f = Nothing
    Set fs = Nothing
    Set xml = Nothing

    Update_Forecast = parse_html("Forecast")
    
End Function

Sub UpdateWeatherIcons

  ResolveForecast(0)
  ResolveForecast(1)
  ResolveForecast(2)
  ResolveForecast(3)
  ResolveForecast(4)

End Sub

Function Forecast_Image(ForecastDay)

  Dim ForecastText, FileNumber
  
  ForecastText = Get_Cache_Value("Forecast Day " & ForecastDay & " Text", forecast_file)
  If ForecastText = "Invalid Data" Then ForecastText = Get_Cache_Value("Forecast Trend Text", forecast_file)

  FileNumber = ForecastTexttoNumber(LCase(ForecastText),ForecastDay)
  
  Forecast_Image = FileNumber & ".png"

End Function

Private Function ForecastTexttoNumber (ForecastText,DayNumber)

  Dim Thunder, Rain, Showers, Fine, PartlyCloudy, MostlyCloudy, Fog, FewShowers, Hail, Snow, TempResult
  Dim fs, MoonPhase

  Thunder = False
  Rain = False
  Showers = False
  Fine = False
  PartlyCloudy = False
  Fog = False
  MostlyCloudy = False
  FewShowers = False
  Hail = False
  Snow = False


  If InStr(ForecastText,"thunderstorm") > 0 Then Thunder = True
  If InStr(ForecastText,"thunder") > 0 Then Thunder = True
  If InStr(ForecastText,"rain") > 0 Then Rain = True
  If InStr(ForecastText,"some rain") > 0 Then Fine = True
  If InStr(ForecastText,"rain at times") > 0 Then Fine = True
  If InStr(ForecastText,"shower") > 0 Then Showers = True
  If InStr(ForecastText,"drizzle") > 0 Then Showers = True
  If InStr(ForecastText,"clear") > 0 Then Fine = True
  If InStr(ForecastText,"sunny") > 0 Then Fine = True
  If InStr(ForecastText,"sunshine") > 0 Then Fine = True
  If InStr(ForecastText," sun") > 0 Then Fine = True
  If InStr(ForecastText,"fine") > 0 Then Fine = True
  If InStr(ForecastText,"mostly clear") > 0 Then PartlyCloudy = True
  If InStr(ForecastText,"cloud developing") > 0 Then PartlyCloudy = True
  If InStr(ForecastText,"mostly sunny") > 0 Then PartlyCloudy = True
  If InStr(ForecastText,"cool change") > 0 Then PartlyCloudy = True
  If InStr(ForecastText,"change later") > 0 Then PartlyCloudy = True
  If InStr(ForecastText,"morning cloud") > 0 Then PartlyCloudy = True
  If InStr(ForecastText,"change developing") > 0 Then PartlyCloudy = True
  If InStr(ForecastText,"mainly fine") > 0 Then PartlyCloudy = True
  If InStr(ForecastText,"late change") > 0 Then PartlyCloudy = True
  If InStr(ForecastText,"becoming fine") > 0 Then PartlyCloudy = True
  If InStr(ForecastText,"cloudy") > 0 Then PartlyCloudy = True
  If InStr(ForecastText,"cloud increasing") > 0 Then PartlyCloudy = True
  If InStr(ForecastText,"cloud clearing") > 0 Then PartlyCloudy = True
  If InStr(ForecastText,"dry ") > 0 Then Fine = True
  If InStr(ForecastText,"dry.") > 0 Then Fine = True
  If InStr(ForecastText,"dry,") > 0 Then Fine = True
  If InStr(ForecastText," dry") > 0 Then Fine = True
  If InStr(ForecastText,"partly cloudy") Then PartlyCloudy = True
  If InStr(ForecastText,"unsettled") Then PartlyCloudy = True
  If InStr(ForecastText,"patchy clouds") Then PartlyCloudy = True
  If InStr(ForecastText,"mostly cloudy") Then MostlyCloudy = True
  If InStr(ForecastText,"few showers") Then FewShowers = True
  If InStr(ForecastText,"shower or two") Then FewShowers = True
  If InStr(ForecastText,"showers redeveloping") Then FewShowers = True
  If InStr(ForecastText,"showers developing") Then FewShowers = True
  If InStr(ForecastText,"fog") Then Fog = True
  If InStr(ForecastText,"hail") Then Hail = True
  If InStr(ForecastText,"snow") Then Snow = True
  
  TempResult = "na"

  If Fine Then TempResult = 32
  If Fine and Not Rain and NOT Showers Then TempResult = 32
  If Not Fine and Rain Then TempResult = 12
  If Not Fine and Not Rain and Showers Then TempResult = 39
  If Fine and Not Rain and Not Showers and PartlyCloudy Then TempResult = 30
  If Fine and Not Rain and Not Showers and MostlyCloudy Then TempResult = 28
  If Fine and Rain Then TempResult = 39
  If Fine and Not Rain and Showers Then TempResult = 39
  If Not Fine and Not Rain and FewShowers Then TempResult = 39
  If Not Fine and Not Rain and Not Showers and Fog Then TempResult = 20
  If Fine and Not Rain and Not Showers and Fog Then TempResult = 34
  If Not Fine and Not Rain and Not Showers and Snow and Hail Then Tempresult = 5
  If Not Fine and Not Rain and Not Showers and Not Snow and Not Hail and MostlyCloudy Then Tempresult = 26
  If Not Fine and Not Rain and Not Showers and Not Snow and Hail Then Tempresult = 6
  If Not Fine and Not Rain and Not Showers and Snow and Not Hail Then Tempresult = 15
  If Not Fine and Not Rain and Not Showers and PartlyCloudy Then TempResult = 30
  If Thunder Then TempResult = 0
  If Thunder and Fine Then TempResult = 37
  
  If (Get_Cache_Value("Night Forecast", forecast_file) = "Yes" and DayNumber = 0 and TempResult <> "na") OR _ 
     (NowText > Sunset_Day0 and DayNumber = 0 and TempResult <> "na") OR _
     (NowText < Sunrise_Day0 and DayNumber = 0 and TempResult <> "na") Then
    If TempResult = 32 Then TempResult = 31
    If TempResult = 12 Then TempResult = 45
    If TempResult = 11 Then TempResult = 45
    If TempResult = 39 Then TempResult = 45
    If TempResult = 28 Then TempResult = 27
    If TempResult = 30 Then TempResult = 29
    If TempResult = 0 Then TempResult = 47  	
    If TempResult = 37 Then TempResult = 47
    If TempResult = 5 Then TempResult = 46
    If TempResult = 6 Then TempResult = 46
    If TempResult = 15 Then TempResult = 46
    If TempResult = 26 Then TempResult = 27
    If TempResult = 34 Then TempResult = 33
    
    MoonPhase = Get_Cache_Value("Moon Phase", forecast_file)
  
    Set fs = CreateObject ("Scripting.FileSystemObject")
   
    If fs.FileExists ("..\images\" & skin & "\" & TempResult & MoonPhase & ".png") Then 
      TempResult = TempResult & MoonPhase
    End If

  End If
    
  ForecastTexttoNumber = TempResult

End Function

Private Function parse_html (filetype)

	Dim fs, fp, f, parsed_data, contents, index

	Set fs = CreateObject ("Scripting.FileSystemObject")
	
	If (fs.FileExists (wTempDir & "/" & log_file & ".html")) Then
	
		Set fp = fs.GetFile (wTempDir & "/" & log_file & ".html")
		Set f = fp.OpenAsTextStream (1, -2)

		contents = f.readall
		f.Close
		
		Set fp = Nothing
		Set fs = Nothing
		Set f = Nothing
		
		If filetype = "Observation" and ObservationType = "Detail" Then parsed_data = parse_detail_observation_data (contents)
		If filetype = "Forecast" and ForecastCity = "Melbourne" Then  parsed_data = parse_melbourne_forecast_data (contents)
		If filetype = "Forecast" And ForecastCity = "Sydney" Then  parsed_data = parse_melbourne_forecast_data (contents)
		If filetype = "Forecast" And ForecastCity = "Brisbane" Then  parsed_data = parse_melbourne_forecast_data (contents)

		contents = parsed_data (0)
		
		For index = 1 To Ubound (parsed_data)
			contents = contents & vbCrLf & parsed_data (index)
		Next
		
		' Rewrite the parsed file contents
		Set fs = CreateObject ("Scripting.FileSystemObject")
		Set f = fs.CreateTextFile (wTempDir & "/" & log_file & ".txt", True)
		f.write (contents)
		f.close
		fs.DeleteFile(log_file & "-Updating.txt") 
		Set f = Nothing
		Set fs = Nothing
		
		contents = parsed_data (0)
	Else
		contents = "No Data"
	End If
	
	parse_html = contents

End Function

Private Function parse_detail_observation_data (ByRef contents)

  Dim DataStart, wStationAbbrev, Temp, wExtremeWindkm, wExtremeWindkts, wJunk

  itemCount = -1

  AddItem "Observation File Updated", Now ()
  AddItem "Observation Updated", parse_item (contents, "Issued at", "</p>")

  
  
  wStationAbbrev = Replace(LCase(Observation_Station)," ","-")
  wStationAbbrev = Replace(wStationAbbrev,")","")
  wStationAbbrev = Replace(wStationAbbrev,"(","")
  
  Temp = parse_item (contents, "station-" & wStationAbbrev, "<a ")

  AddItem "Station Name", parse_item (contents, ".shtml"">", "</a>")
  
  wJunk = parse_item (contents, "-datetime", "</a>")
  
  AddItem "Station Update", ConvertDetObsDate(parse_item (contents, "station-" & wStationAbbrev & """>", "</td>"))

  wJunk = parse_item (contents, "-tmp", "</a>")

  AddItem "Current Temp", parse_item (contents, "station-" & wStationAbbrev & """>", "</td>")

  wJunk = parse_item (contents, "-apptmp", "</a>")

  AddItem "App Temp", parse_item (contents, "station-" & wStationAbbrev & """>", "</td>")

  wJunk = parse_item (contents, "-dewpoint", "</a>")

  AddItem "Dew Point", parse_item (contents, "-station-" & wStationAbbrev & """>", "</td>")

  wJunk = parse_item (contents, "-relhum", "</a>")

  AddItem "Relative Humidity", parse_item (contents, "-station-" & wStationAbbrev & """>", "</td>")

  wJunk = parse_item (contents, "-delta-t", "</a>")

  AddItem "Delta-T", parse_item (contents, "-station-" & wStationAbbrev & """>", "</td>")

  wJunk = parse_item (contents, "-wind-dir", "</a>")

  AddItem "Wind Direction", parse_item (contents, "station-" & wStationAbbrev & """>", "</td>")

  wJunk = parse_item (contents, "-wind-spd-kmh", "</a>")

  AddItem "Wind Speed km", parse_item (contents, "station-" & wStationAbbrev & """>", "</td>")

  wJunk = parse_item (contents, "-wind-gust-kmh", "</a>")

  AddItem "Wind Gust km", parse_item (contents, "-station-" & wStationAbbrev & """>", "</td>")

  wJunk = parse_item (contents, "-wind-spd-kts", "</a>")

  AddItem "Wind Speed knots", parse_item (contents, "-station-" & wStationAbbrev & """>", "</td>")

  wJunk = parse_item (contents, "-wind-gust-kts", "</a>")

  AddItem "Wind Gust knots", parse_item (contents, "-station-" & wStationAbbrev & """>", "</td>")

  wJunk = parse_item (contents, "-press t", "</a>")

  AddItem "Pressure hPa", parse_item (contents, "station-" & wStationAbbrev & """>", "</td>")

  wJunk = parse_item (contents, "-rainsince9am t", "</a>")

  AddItem "Rain Since 9am mm", parse_item (contents, "station-" & wStationAbbrev & """>", "</td>")

  wJunk = parse_item (contents, "-lowtmp t", "</a>")

  AddItem "Extreme Min", parse_item (contents, "station-" & wStationAbbrev & """>", "<br />")
  AddItem "Extreme Min Time", "00000000:" & ConvertDetObsTime(parse_item (contents, "<small>", "</small>"))

  wJunk = parse_item (contents, "-hightmp t", "</a>")

  AddItem "Extreme Max", parse_item (contents, "station-" & wStationAbbrev & """>", "<br />")
  AddItem "Extreme Max Time", "00000000:" & ConvertDetObsTime(parse_item (contents, "<small>", "</small>"))

  wJunk = parse_item (contents, "-highwind-dir t", "</a>")

  AddItem "Extreme Wind Dir", parse_item (contents, "station-" & wStationAbbrev & """>", "</td>")

  wJunk = parse_item (contents, "-highwind-gust-kmh t", "</a>")
  
  wExtremeWindkm = parse_item (contents, "station-" & wStationAbbrev & """>", "</td>")
  
  If InStr(wExtremeWindkm,"<small>") > 0 Then
    AddItem "Extreme Wind km", parse_item (contents, "","<br />")
    AddItem "Extreme Wind Time", "00000000:" & ConvertDetObsTime(parse_item (contents, "<small>", "</small>"))
  Else
    AddItem "Extreme Wind km", wExtremeWindkm
    AddItem "Extreme Wind Time", "-"
  End If

  wJunk = parse_item (contents, "-highwind-gust-kts t", "</a>")
    
  wExtremeWindkts = parse_item (contents, "station-" & wStationAbbrev & """>", "</td>")
  
  If InStr(wExtremeWindkts,"<small>") > 0 Then
    AddItem "Extreme Wind knots", parse_item (contents, "", "<br />")
  Else
    AddItem "Extreme Wind knots", wExtremeWindkts
  End If  
  
  AddItem "End of File", Now()

  parse_detail_observation_data = parsed_data

End Function

Private Function parse_item (ByRef contents, start_tag, end_tag)

	Dim position, item
	
	position = InStr (1, contents, start_tag, vbTextCompare)

	If position > 0 Then
		' Trim the html information.
		contents = mid (contents, position + len (start_tag))
		position = InStr (1, contents, end_tag, vbTextCompare)
		
		If position > 0 Then
			item = mid (contents, 1, position - 1)
		Else
			item = "Invalid Data"
		End If
	Else
		item = "Invalid Data"
	End If

	parse_item = Trim(Item)

End Function

Private Sub AddItem (Element, NewItem)

  Dim wElementTag
  itemCount = itemCount + 1
  ReDim Preserve parsed_data (itemCount)
  
  NewItem = Replace(NewItem,Chr(10)," ")
  NewItem = Replace(NewItem,"<C10>"," ")
  NewItem = Replace(NewItem,Chr(13)," ")
  NewItem = Replace(NewItem,"  "," ")
  NewItem = Replace(NewItem,"  "," ")
  NewItem = Replace(NewItem,"  "," ")
  NewItem = Replace(NewItem,Chr(9)," ")
  NewItem = Replace(NewItem,"&nbsp;"," ")
  NewItem = Replace(NewItem,"-9999.0","NA")
  NewItem = Replace(NewItem,"-9999","NA")
  NewItem = Replace(NewItem,"&nbsp;","")
  NewItem = Trim(NewItem)
  
  wElementTag = Replace(Element," ","")
  
  parsed_data (itemCount) = "<" & wElementTag & ">" & NewItem & "</" & wElementTag & ">"
  
End Sub

Private Function standardise_contents (ByRef contents)

  Dim Temp

  Temp = contents

  Temp = Replace(Temp,vbCRLF,"<C10>")
  Temp = Replace(Temp,vbLF,"<C10>")
  Temp = Replace(Temp,Chr(10),"<C10>")
  Temp = Replace(Temp,Chr(13),"<C10>")
  Temp = Replace(Temp,Chr(9),"<C10>")
  
  standardise_contents = Temp

End Function

Private Function parse_melbourne_forecast_data (ByRef contents)

  itemCount = -1
  
  contents = standardise_contents(contents)
  
  AddItem "Forecast File Updated", Now ()
  AddItem "Forecast URL", Forecast_URL
  AddItem "Forecast For", ForecastCity
  
  If InStr(LCase(contents),"updated at") < InStr(LCase(contents),"forecast for") Then
    AddItem "Forecast Update", parse_item (contents, "updated at ", ".</p>")
  Else
    AddItem "Forecast Update", parse_item (contents, "issued at ", ".</p>")
  End If
  
  Day0 = parse_item (contents, "Forecast For ", "</h2>")
  Day0 = Trim(Replace(Day0,"the rest of","The rest of"))

  AddItem "Forecast Day 0", Day0

  If DatePart("h", Now()) >= 18 OR DatePart("h", Now()) < 5 Then
    Item = "Yes"
  Else
    Item = "No"
  End If
 
  AddItem "Night Forecast", Item
  
  If InStr(LCase(Day0),"rest of") > 0 Then

    'Part way through the day

    If InStr(contents, "class=""max"">") < InStr(contents,"</p>") Then ' Check for a Max Temp
      AddItem "Forecast Day 0 Max", parse_item (contents, "class=""max"">", "</em>")
    Else
      AddItem "Forecast Day 0 Max", ""
    End If

    AddItem "Forecast Day 0 Text", parse_item (contents, "<p>", "</p>")
    AddItem "Forecast Day 0 Min", ""
    
    AddItem "Forecast Day 1", parse_item (contents, "<h2>", "</h2>")
    AddItem "Forecast Day 1 Min", parse_item (contents, "class=""min"">", "</em>")
    AddItem "Forecast Day 1 Max", parse_item (contents, "class=""max"">", "</em>")
    AddItem "Forecast Day 1 Text", parse_item (contents, "<p>", "</p>")
    
'    If Instr(contents,"UV Index") > 0 Then
'      If InStr(1,contents,"UV Index:",1) > 0 Then
'        AddItem "UV Index", parse_item (contents, "UV Index", "</p>")
'      Else
'        AddItem "UV Index", parse_item (contents, "UV Alert", "</p>")
'      End If
'    End If

  End If
  
  AddItem "Forecast Day 2", parse_item (contents, "<h2>", "</h2>")
  AddItem "Forecast Day 2 Min", parse_item (contents, "class=""min"">", "</em>")
  AddItem "Forecast Day 2 Max", parse_item (contents, "class=""max"">", "</em>")
  AddItem "Forecast Day 2 Text", parse_item (contents, "<p>", "</p>")

  AddItem "Forecast Day 3", parse_item (contents, "<h2>", "</h2>")
  AddItem "Forecast Day 3 Min", parse_item (contents, "class=""min"">", "</em>")
  AddItem "Forecast Day 3 Max", parse_item (contents, "class=""max"">", "</em>")
  AddItem "Forecast Day 3 Text", parse_item (contents, "<p>", "</p>")

  AddItem "Forecast Day 4", parse_item (contents, "<h2>", "</h2>")
  AddItem "Forecast Day 4 Min", parse_item (contents, "class=""min"">", "</em>")
  AddItem "Forecast Day 4 Max", parse_item (contents, "class=""max"">", "</em>")
  AddItem "Forecast Day 4 Text", parse_item (contents, "<p>", "</p>")

  AddItem "Forecast Day 5", parse_item (contents, "<h2>", "</h2>")
  AddItem "Forecast Day 5 Min", parse_item (contents, "class=""min"">", "</em>")
  AddItem "Forecast Day 5 Max", parse_item (contents, "class=""max"">", "</em>")
  AddItem "Forecast Day 5 Text", parse_item (contents, "<p>", "</p>")

  AddItem "Forecast Day 6", parse_item (contents, "<h2>", "</h2>")
  AddItem "Forecast Day 6 Min", parse_item (contents, "class=""min"">", "</em>")
  AddItem "Forecast Day 6 Max", parse_item (contents, "class=""max"">", "</em>")
  AddItem "Forecast Day 6 Text", parse_item (contents, "<p>", "</p>")

  GetSunRiseInfo
  
  AddItem "Moon Phase", MoonPhaseInfo()
  
  AddItem "End of File", Now()

  parse_melbourne_forecast_data = parsed_data

End Function

Private Function parse_sydney_forecast_data (ByRef contents)

  Dim TrendDays, TrendText

  itemCount = -1

  contents = standardise_contents(contents)
  
  AddItem "Forecast File Updated", Now ()
  AddItem "Forecast URL", Forecast_URL
  AddItem "Forecast For", "Sydney"
  
  If InStr(LCase(contents),"updated at") < InStr(LCase(contents),"forecast for") Then
    AddItem "Forecast Update", parse_item (contents, "updated at ", "<C10>")
  Else
    AddItem "Forecast Update", parse_item (contents, "issued at ", "<C10>")
  End If
  
  AddItem "Forecast Day 0", parse_item (contents, "Forecast For ", "<C10>")

  If DatePart("h", Now()) >= 18 OR DatePart("h", Now()) < 5 Then
    Item = "Yes"
  Else
    Item = "No"
  End If
 
  AddItem "Night Forecast", Item

  If Instr(contents, "Fire danger") = 0 Then
    AddItem "Forecast Day 0 Text", parse_item (contents, "<C10>", "Precis")
  Else
    AddItem "Forecast Day 0 Text", parse_item (contents, "<C10>", "Fire danger")
  End If
  
  If InStr(contents,"Forecast for ") > 0 Then
    'Night Forecast - Min and Max
    AddItem "Forecast Day 0 Min", ""
    If InStr(contents, " Max: ") <  InStr(contents,"Forecast for ") Then
      AddItem "Forecast Day 0 Max", parse_item (contents, "Max: ", "Par")
    Else
      AddItem "Forecast Day 0 Max", ""
    End If
    If Instr(contents, "Forecast for") > Instr(contents,"UV Index") Then
      AddItem "UV Index", parse_item (contents, "UV Index:", "<C10>")
    End If
    AddItem "Forecast Day 1", parse_item (contents, "Forecast for ", "<C10>")
    AddItem "Forecast Day 1 Text", parse_item (contents, "<C10>", "Precis")
    AddItem "Forecast Day 1 Min", parse_item (contents, "Min: ", "Max:")
    If Instr(contents, "Parram") > 0 Then
      AddItem "Forecast Day 1 Max", parse_item (contents, "Max: ", "Parram")
    Else
      AddItem "Forecast Day 1 Max", parse_item (contents, "Max: ", "<C10>")
    End If
    If Instr(contents, "UV Index") > 0 Then
      AddItem "UV Index", parse_item (contents, "UV Index:", "<C10>")
    End If
  Else
    'DayTime Forecast - No Min
    AddItem "Forecast Day 0 Min", ""
    AddItem "Forecast Day 0 Max", parse_item (contents, " Max:", "Par")
    AddItem "UV Index", parse_item (contents, "UV Index:", "<C10>")
    AddItem "Forecast Day 1", parse_item (contents,  "<C10>", "day") & "day"
    AddItem "Forecast Day 1 Text", parse_item (contents, "day", "City:")
    AddItem "Forecast Day 1 Min", parse_item (contents, "Min:", "Max:")
    AddItem "Forecast Day 1 Max", parse_item (contents, "Max:", "<C10>")
  End If	  
	
  AddItem "Forecast Day 2", parse_item (contents, "<C10>" & "<C10>", "day") & "day"
  AddItem "Forecast Day 2 Text", parse_item (contents, "day", "City:")
  AddItem "Forecast Day 2 Min", parse_item (contents, " Min: ", " Max:")
  AddItem "Forecast Day 2 Max", parse_item (contents, " Max: ", "<C10>")

  AddItem "Forecast Day 3", parse_item (contents, "<C10>" & "<C10>", "day") & "day"
  AddItem "Forecast Day 3 Text", parse_item (contents, "day", "City:")
  AddItem "Forecast Day 3 Min", parse_item (contents, " Min: ", " Max:")
  AddItem "Forecast Day 3 Max", parse_item (contents, " Max: ", "<C10>")

  Item = parse_item (contents, "<C10>" & "<C10>", "day") & "day"
  AddItem "Forecast Trend Days", Item
  AddItem "Forecast Day 4", Item

  Item = parse_item (contents, "day", "City:")
  AddItem "Forecast Trend Text", Item
  AddItem "Forecast Day 4 Text", Item
  
  AddItem "Forecast Day 4 Min", parse_item (contents, " Min: ", " Max:")
  AddItem "Forecast Day 4 Max", parse_item (contents, " Max: ", "<C10>")

  AddItem "Forecast Day 5", parse_item (contents, "<C10>" & "<C10>", "day") & "day"
  AddItem "Forecast Day 5 Text", parse_item (contents, "day", "City:")
  AddItem "Forecast Day 5 Min", parse_item (contents, " Min: ", " Max:")
  AddItem "Forecast Day 5 Max", parse_item (contents, " Max: ", "<C10>")

  AddItem "Forecast Day 6", parse_item (contents, "<C10>" & "<C10>", "day") & "day"
  AddItem "Forecast Day 6 Text", parse_item (contents, "day", "City:")
  AddItem "Forecast Day 6 Min", parse_item (contents, " Min: ", " Max:")
  AddItem "Forecast Day 6 Max", parse_item (contents, " Max: ", "<C10>")
	
  GetSunRiseInfo
  GetTideInfo

  AddItem "Moon Phase", MoonPhaseInfo()
  AddItem "End of File", Now()

  parse_sydney_forecast_data = parsed_data

End Function

Private Function GetSunRiseInfo()

  Dim xml, LatDeg, LatMin, LongDeg, LongMin, TimeOffSet, CurrentDay, f, fs, wLongLatURL
	
  If SunriseLocation <> "" Then
  	
    CurrentDay = Now()
	
    'First Determine the Longitude/Latitude and Time Difference
    Set xml = CreateObject("Microsoft.XMLHTTP")
    wLongLatURL = "http://www.ga.gov.au/bin/geodesy/run/gazmap_sunrise?placename=" & Replace(SunriseLocation," ","+") & "&placetype=R&state=" & State
    xml.Open "POST", wLongLatURL, False, ProxyUsername, ProxyPassword
    xml.Send
	
    contents = xml.responseText
    contents = CStr(contents)
    	
    Item = parse_item (contents, "document.Sunrise.Location.value='" & SunriseLocation,"(" & TimeZone & ")")

    LatDeg = parse_item (contents, "LatDeg.value=",";")
    LatMin = parse_item (contents, "LatMin.value=",";")
    LongDeg = parse_item (contents, "LongDeg.value=",";")
    LongMin = parse_item (contents, "LongMin.value=",";")

    contents = parse_item(contents, "austzone", "(" & TimeZone & ")")

    contents = Mid(contents, InStrrev(contents, "Value=", -1, vbTextCompare))
	
    TimeOffSet = parse_item(contents, "Value=""", """")
    TimeOffSet = Replace(TimeOffSet,"+","")
  
    If ActiveTimeBias <> TimeBias Then
      DayLightSavings = (DayLightSavings/-60)
      TimeOffSet = TimeOffSet' + DayLightSavings
    End If
	
    xml.Open "POST", "http://www.ga.gov.au/bin/geodesy/run/sunrisenset", False, ProxyUsername, ProxyPassword
    xml.Send "&Location="& SunriseLocation & "&LatDeg=" & LatDeg & "&LatMin=" & LatMin & _ 
             "&LongDeg=" & LongDeg & "&LongMin=" & LongMin & _ 
             "&TimeZone=" & TimeOffSet & "&Event=1&Date=" & _
             DatePart("d",CurrentDay)&"/"&DatePart("m",CurrentDay)&"/"&DatePart("yyyy",CurrentDay)

    contents = xml.responseText
    
    'Set fs = CreateObject ("Scripting.FileSystemObject")
    'Set f = fs.CreateTextFile(log_file & "-sunset-1.html", True)
    'f.write contents
    'f.close

    Item = parse_item (contents, "Sunset Results","</listing")
      
    contents = parse_item (contents, "time zone","/listing")

    Item = parse_item (contents, "Rise ","Set")
    
    AddItem "Day 0 SunRise", Mid(Item,1,2) & ":" & Mid(Item,3,2)
    Item = parse_item (contents, "Set ","<")
    AddItem "Day 0 SunSet", Mid(Item,1,2) & ":" & Mid(Item,3,2)

    xml.Open "POST", "http://www.ga.gov.au/bin/geodesy/run/moonrisenset", False, ProxyUsername, ProxyPassword
    xml.Send "&LatDeg=" & LatDeg & "&LatMin=" & LatMin & _ 
           "&LongDeg=" & LongDeg & "&LongMin=" & LongMin & _ 
           "&TimeZone=" & TimeOffSet & "&Event=1&Date=" & _
           DatePart("d",CurrentDay)&"/"&DatePart("m",CurrentDay)&"/"&DatePart("yyyy",CurrentDay)

    contents = xml.responseText

    'Set fs = CreateObject ("Scripting.FileSystemObject")
    'Set f = fs.CreateTextFile(log_file & "-moon-1.html", True)
    'f.write contents
    'f.close
    
    Item = parse_item (contents, "Moonset Results","</listing")
  
    contents = parse_item (contents, "time zone","/listing")
    
    Item = parse_item (contents, "Rise: ","Set:")
    AddItem "Day 0 MoonRise", Mid(Item,1,2) & ":" & Mid(Item,3,2)

    Item = Trim(Replace(parse_item (contents, "Set: ","<"),chr(10),""))
     
    If Item = "" Then Item = "0000"

    AddItem "Day 0 MoonSet", Mid(Item,1,2) & ":" & Mid(Item,3,2)

    CurrentDay = DateAdd("d", 1, CurrentDay)

    xml.Open "POST", "http://www.ga.gov.au/bin/astro/sunrisenset", False, ProxyUsername, ProxyPassword
    xml.Send "&LatDeg=" & LatDeg & "&LatMin=" & LatMin & _ 
           "&LongDeg=" & LongDeg & "&LongMin=" & LongMin & _ 
           "&TimeZone=" & TimeOffSet & "&Event=1&Date=" & _
           DatePart("d",CurrentDay)&"/"&DatePart("m",CurrentDay)&"/"&DatePart("yyyy",CurrentDay)

    contents = xml.responseText

    'Set fs = CreateObject ("Scripting.FileSystemObject")
    'Set f = fs.CreateTextFile(log_file & "-sunset-2.html", True)
    'f.write contents
    'f.close
  
    Item = parse_item (contents, "Sunset Results","</listing")
  
    contents = parse_item (contents, "time zone","/listing")

    Item = parse_item (contents, "Rise ","Set")
    AddItem "Day 1 SunRise", Mid(Item,1,2) & ":" & Mid(Item,3,2)
    Item = parse_item (contents, "Set ","<")
    AddItem "Day 1 SunSet", Mid(Item,1,2) & ":" & Mid(Item,3,2)

    xml.Open "POST", "http://www.ga.gov.au/bin/astro/moonrisenset", False, ProxyUsername, ProxyPassword
    xml.Send "&LatDeg=" & LatDeg & "&LatMin=" & LatMin & _ 
             "&LongDeg=" & LongDeg & "&LongMin=" & LongMin & _ 
             "&TimeZone=" & TimeOffSet & "&Event=1&Date=" & _
             DatePart("d",CurrentDay)&"/"&DatePart("m",CurrentDay)&"/"&DatePart("yyyy",CurrentDay)

    contents = xml.responseText
    
    'Set fs = CreateObject ("Scripting.FileSystemObject")
    'Set f = fs.CreateTextFile(log_file & "-moon-2.html", True)
    'f.write contents
    'f.close
    
    Item = parse_item (contents, "Moonset Results","</listing")
  
    contents = parse_item (contents, "time zone","/listing")
    
    Item = parse_item (contents, "Rise: ","Set:")
    AddItem "Day 1 MoonRise", Mid(Item,1,2) & ":" & Mid(Item,3,2)
    Item = parse_item (contents, "Set: ","<")
    AddItem "Day 1 MoonSet", Mid(Item,1,2) & ":" & Mid(Item,3,2)
  
    Set xml = Nothing
    
  End If

End Function

Private Function MoonPhaseInfo()
  
  Dim MoonPhaseInt, wLastFullMoonDate, wFullMoonDate, f, fs, wTemp, wDaysDiff, wEOF, wDayOfCycle
	
  ' Updated 24/12/2014 to use Full Moon Data, and improve readability
  ' The last known source of this file is http://www.ga.gov.au/earth-monitoring/astronomical-information/moon-phase-data.html
  
  Set fs = CreateObject ("Scripting.FileSystemObject")
  Set f = fs.OpenTextFile ("FullMoons.csv", ForReading)

  wEOF = False
  
  wTemp = f.ReadLine 'Junk the header

  Do While f.AtEndOfStream = False and wEOF = False

    wFullMoonDate = f.ReadLine
    wDaysDiff = DateDiff("d",wFullMoonDate,Now())
    If wDaysDiff =< 0 Then 
      wEOF = True
    Else
      wLastFullMoonDate = wFullMoonDate
    End If  
  Loop

  f.close

  wDaysDiff = DateDiff("d",wLastFullMoonDate,Now())

  'Weather Icon Formats NewMoon - 1 First Quarter - 3 Full - 5 LastQuarter - 7
  'We need to convert the number of days since last known full moon to one of these
  'Approx Lunar Cycle is 28 days so start by getting a number from 0-27
  
  wDayOfCycle = wDaysDiff Mod 27
  
  ' There are tidier ways to do this, but to save my sanity heres a simple conversion from Day of the Cycle to an Image suffix
  
  Select Case wDayOfCycle
   Case  0 MoonPhaseInt = 5
   Case  1 MoonPhaseInt = 5
   Case  2 MoonPhaseInt = 5
   Case  3 MoonPhaseInt = 4
   Case  4 MoonPhaseInt = 4
   Case  5 MoonPhaseInt = 4
   Case  6 MoonPhaseInt = 3
   Case  7 MoonPhaseInt = 3
   Case  8 MoonPhaseInt = 3
   Case  9 MoonPhaseInt = 3
   Case 10 MoonPhaseInt = 2
   Case 11 MoonPhaseInt = 2
   Case 12 MoonPhaseInt = 2
   Case 13 MoonPhaseInt = 1
   Case 14 MoonPhaseInt = 1
   Case 15 MoonPhaseInt = 1
   Case 16 MoonPhaseInt = 1
   Case 17 MoonPhaseInt = 8
   Case 18 MoonPhaseInt = 8
   Case 19 MoonPhaseInt = 8
   Case 20 MoonPhaseInt = 7
   Case 21 MoonPhaseInt = 7
   Case 22 MoonPhaseInt = 7
   Case 23 MoonPhaseInt = 7
   Case 24 MoonPhaseInt = 6
   Case 25 MoonPhaseInt = 6
   Case 26 MoonPhaseInt = 6
   Case 27 MoonPhaseInt = 5
  End Select

  If FileTracking Then
    Set fs = CreateObject ("Scripting.FileSystemObject")
    Set f = fs.OpenTextFile(log_file & "-moonphase.log", ForAppending,True,0)
    f.writeline Now() &  "Last Full Moon Date:" & wLastFullMoonDate & " DayOfCycle: " & wDayOfCycle & " Suffix: " & MoonPhaseInt
  End If

  MoonPhaseInfo = "_"& MoonPhaseInt
    
End Function

Sub RaiseException (pErrorSection, pErrorCode, pErrorMessage)

    Dim errfs, errf, errContent
    
    Set errfs = CreateObject ("Scripting.FileSystemObject")
    Set errf = errfs.CreateTextFile(log_file & "-errors.txt", True)
    
    errContent = Now() & vbCRLF & vbCRLF & _
                 pErrorSection & vbCRLF & _
                 "Error Code: " & pErrorCode & vbCRLF & _
                 "--------------------------------------" & vbCRLF & _
                 pErrorMessage
    errf.write errContent
    errf.close
    
    If FileTracking Then
      Set errf = errfs.CreateTextFile (log_file & "-errors-" & UpdateTimeStamp & ".txt", True)
      errf.write errContent
      errf.close
    End If

    Set errf = Nothing
    
    If errfs.FileExists(log_file & "-Updating.txt") Then errfs.DeleteFile(log_file & "-Updating.txt") 

    Set errfs = Nothing
    
    WScript.Quit

End Sub

Function MyLPad (MyValue, MyPadChar, MyPaddedLength) 
  MyLpad = String(MyPaddedLength - Len(MyValue), MyPadChar) & MyValue 
End Function

Dim fs, f, wResponse, InTime, wRegExp, wMeasureDefs, wMeasureIdx, RadarLocation, UpdateTimeStamp


   InTime = Now()
   UpdateTimeStamp = Year(InTime) & MyLpad(Month(InTime),"0",2) & MyLpad(Day(InTime),"0",2) & "-" & MyLpad(Hour(InTime),"0",2) & MyLpad(Minute(InTime),"0",2) & MyLpad(Second(InTime),"0",2)

   
   Set fs = CreateObject ("Scripting.FileSystemObject")

   If fs.FileExists(wAppDir & "\bomWeather-Configuration.txt") Then
      Set f = fs.OpenTextFile(wAppDir & "\bomWeather-Configuration.txt")
      wbomDetails = f.readall
      f.close
      ForecastCity = parse_item (wbomDetails, "ForecastCity =", "<<<")
      forecast_url = parse_item (wbomDetails, "forecast_url =", "<<<")
      observation_url = parse_item (wbomDetails, "observation_url =", "<<<")
      observation_station = parse_item (wbomDetails, "observation_station =", "<<<")
      ObservationType = parse_item (wbomDetails, "ObservationType =", "<<<")
      SunriseLocation = parse_item (wbomDetails, "SunriseLocation =", "<<<")
      State = parse_item (wbomDetails, "State =", "<<<")
      TimeZone = parse_item (wbomDetails, "TimeZone =", "<<<")
      RadarLocation = parse_item (wbomDetails, "RadarLocation =", "<<<")
    Else
      MsgBox("Please run bomWeatherSetup.vbs to set up your configuration")
      wScript.Quit
   End If


   If Not fs.FolderExists(wTempDir) Then fs.CreateFolder(wTempDir)
   
   wResponse = update_forecast()
   wResponse = update_observation()

   wRegExp = ""
   
   wMeasureDefs = ""
   wMeasureIdx = 1

   Set f = fs.CreateTextFile ("bomWeather-calculations.txt", True)

   f.writeline FormatCalc("StationAt", Station_At)
   f.writeline FormatCalc("CurrentTemp", Current_Temp)
   f.writeline FormatCalc("AppTemp", App_Temp)	' Craig
   f.writeline FormatCalc("ObservedMaxTempTime", Observed_MaxTempTime)
   f.writeline FormatCalc("CurrentPressure", Current_Pressure)
   f.writeline FormatCalc("CurrentRelHumidity", Current_Rel_Humidity)
   f.writeline FormatCalc("CurrentRainfall", Current_RainFall)
   f.writeline FormatCalc("CurrentWindDirSpeed", Current_WindDirSpeed)	' Craig
   f.writeline FormatCalc("CurrentForecastText", Current_Forecast_Text)
   f.writeline FormatCalc("CurrentForecastShortText", Current_Forecast_ShortText)
   f.writeline FormatCalc("CurrentForecastImage", Forecast_Image(0))


   f.writeline FormatCalc("Day1ForecastImage", Forecast_Image(1))
   f.writeline FormatCalc("Day1ShortCapName", Day_1_ShortCapName)
   f.writeline FormatCalc("Day1HighLow", Day_1_HighLow)
   f.writeline FormatCalc("Day1Forecast", Day_1_Forecast)

   f.writeline FormatCalc("Day2ForecastImage", Forecast_Image(2))
   f.writeline FormatCalc("Day2ShortCapName", Day_2_ShortCapName)
   f.writeline FormatCalc("Day2HighLow", Day_2_HighLow)
   f.writeline FormatCalc("Day2Forecast", Day_2_Forecast)

   f.writeline FormatCalc("Day3ForecastImage", Forecast_Image(3))
   f.writeline FormatCalc("Day3ShortCapName", Day_3_ShortCapName)
   f.writeline FormatCalc("Day3HighLow", Day_3_HighLow)
   f.writeline FormatCalc("Day3Forecast", Day_3_Forecast)

   f.writeline FormatCalc("Day4ForecastImage", Forecast_Image(4))
   f.writeline FormatCalc("Day4ShortCapName", Day_4_ShortCapName)
   f.writeline FormatCalc("Day4HighLow", Day_4_HighLow)
   f.writeline FormatCalc("Day4Forecast", Day_4_Forecast)

   f.writeline FormatCalc("Day5ForecastImage", Forecast_Image(5))
   f.writeline FormatCalc("Day5ShortCapName", Day_5_ShortCapName)
   f.writeline FormatCalc("Day5HighLow", Day_5_HighLow)
   f.writeline FormatCalc("Day5Forecast", Day_5_Forecast)

   f.writeline FormatCalc("Day6ForecastImage", Forecast_Image(6))
   f.writeline FormatCalc("Day6ShortCapName", Day_6_ShortCapName)
   f.writeline FormatCalc("Day6HighLow", Day_6_HighLow)
   f.writeline FormatCalc("Day6Forecast", Day_6_Forecast)

   f.writeline FormatCalc("RadarLocation",  RadarLocation)

   f.writeline FormatCalc("LastUpdate", InTime)

   f.close
   
   If GenerateMeasureSection Then
     Set fs = CreateObject ("Scripting.FileSystemObject")
     Set f = fs.CreateTextFile ("bomWeather-measures.txt", True)
     f.WriteLine "[MeasurebomWeather]"
     f.WriteLine "Measure=Plugin"
     f.WriteLine "Plugin=Plugins\WebParser.dll"
     f.WriteLine "UpdateRate=60"
     f.WriteLine "CodePage=1252"
     f.WriteLine "Url=file://#@#Scripts\bomWeather-calculations.txt"
     f.WriteLine "RegExp=""(?siU)" & wRegExp & """"
     f.WriteLine
     f.WriteLine wMeasureDefs
   End If 
   
   Set f = Nothing
   Set fs = Nothing
   