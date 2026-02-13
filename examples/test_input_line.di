<!-- Test line-by-line input from stdin -->
<dirac>
  <output>Reading one line from stdin...</output>
  
  <assign name="line1">
    <input source="stdin" mode="line"/>
  </assign>
  
  <output>Got line: '<variable name="line1"/>'</output>
</dirac>
