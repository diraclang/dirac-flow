<!-- Test basic input from stdin -->
<dirac>
  <output>TEST: Script started</output>
  
  <output>TEST: Before defvar</output>
  <defvar name="data">
    <input source="stdin" mode="all"/>
  </defvar>
  
  <output>TEST: After defvar</output>
  <output>Read from stdin: '<variable name="data"/>'</output>
</dirac>
