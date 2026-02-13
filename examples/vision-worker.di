<!-- 
  Vision worker - analyzes images with LLaVA
  Reads DIRAC commands from stdin, outputs DIRAC results to stdout
-->
<dirac>
  <!-- Read command from stdin -->
  <input name="command" source="stdin" mode="all"/>
  
  <!-- Define analyze job -->
  <subroutine name="analyze">
    <parameters>
      <parameter name="image"/>
      <parameter name="timestamp"/>
    </parameters>
    
    <!-- Analyze image with LLaVA -->
    <llm name="analysis" model="llava" image="<variable name='image'/>">
      What do you see in this image? Describe in detail.
    </llm>
    
    <!-- Output result as DIRAC XML to stdout -->
    <output>&lt;result image="<variable name="image"/>" timestamp="<variable name="timestamp"/>"&gt;<variable name="analysis"/>&lt;/result&gt;</output>
  </subroutine>
  
  <!-- Execute whatever command came in -->
  <execute><variable name="command"/></execute>
</dirac>
