<!-- 
  Simple test worker - echoes input with modification
  Reads DIRAC commands from stdin, outputs to stdout
-->
<dirac>
  <!-- Define echo job -->
  <subroutine name="echo">
    <parameters select="@message"/>
    <output><variable name="message"/> - processed!</output>
  </subroutine>
  
  <!-- Read command from stdin into variable -->
  <defvar name="command">
    <input source="stdin" mode="all"/>
  </defvar>
  
  <!-- Execute the command -->
  <execute source="command"/>
</dirac>
