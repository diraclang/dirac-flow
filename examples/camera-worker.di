<!-- 
  Camera worker - captures images from camera
  Reads DIRAC commands from stdin, outputs DIRAC results to stdout
-->
<dirac>
  <!-- Read command from stdin -->
  <input name="command" source="stdin" mode="all"/>
  
  <!-- Define capture job -->
  <subroutine name="capture">
    <eval name="timestamp">Date.now()</eval>
    <defvar name="outputPath">./capture-<variable name="timestamp"/>.jpg</defvar>
    
    <!-- Capture image using ffmpeg -->
    <system name="captureResult">
      ffmpeg -y -f avfoundation -framerate 30 -video_size 1920x1440 -i "3" -frames:v 1 -vf "hflip,vflip" <variable name="outputPath"/> 2>&amp;1 | tail -5
    </system>
    
    <!-- Output result as DIRAC XML to stdout -->
    <output>&lt;analyze image="<variable name="outputPath"/>" timestamp="<variable name="timestamp"/>" /&gt;</output>
  </subroutine>
  
  <!-- Execute whatever command came in -->
  <execute><variable name="command"/></execute>
</dirac>
