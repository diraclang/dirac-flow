<!-- 
  Telegram Worker - Processes messages with LLM
  
  Input format (from queue):
    <message chat_id="123456" text="user message" sender="John" />
  
  Output format (to queue):
    <reply chat_id="123456"><![CDATA[bot response]]></reply>
  
  Dialog Persistence:
  - Loads conversation history from file: ../queues/telegram-dialogs/{chat_id}.json
  - Uses context="chat_dialog" to maintain conversation across messages
  - Saves updated history back to file after each LLM response
-->
<dirac>
 <!-- <import src="dirac/lib/native-tags.di" /> -->
 <import src="dirac/lib/ai.di" />
  
  <!-- Read message from stdin (provided by queue system) -->
  <defvar name="command"><input source="stdin" mode="all"/></defvar>
  
  <!-- Define message handler -->
  <subroutine name="message" 
              param-chat_id="string:required:Telegram chat ID" 
              param-text="string:required:User message text" 
              param-sender="string:optional:Sender name">
    <!-- 1. Load dialog history from file -->
    <defvar name="dialog_file" trim="true">../queues/telegram-dialogs/<variable name="chat_id" />.json</defvar>
    <defvar name="chat_dialog" trim="true">
      <system>cat "<variable name="dialog_file" />" 2>/dev/null || echo '[]'</system>
    </defvar>

    <defvar name="trimmed_text" trim="true"><variable name="text" /></defvar>
    
    <!-- 2. Process with LLM (context attribute manages the dialog) -->
   <!-- <load-context><variable name="trimmed_text" /></load-context> -->
   <output file="/tmp/worker.log">===== Worker Start: <system>date</system> PID: <system>echo $$</system> =====</output>
   <output file="/tmp/worker.log">Working directory: <system>pwd</system></output>
   <output file="/tmp/worker.log">Before load-context</output>
   <!-- <load-context output="context_result">Play YouTube video about Mazda 3</load-context> -->
   <output file="/tmp/worker.log">Load-context result: <variable name="context_result" /></output>
   <output file="/tmp/worker.log">###parameter text is :###</output>
   <output file="/tmp/worker.log">##:<variable name="trimmed_text" /></output>
   <output file="/tmp/worker.log"><list-subroutines /></output>
   <output file="/tmp/worker.log">===== Worker End =====</output>
   <!-- <llm execute="true" context="chat_dialog" output="response">
      <variable name="text"/>
    </llm> -->
    <defvar name="response"><ai><variable name="text" /></ai></defvar> 
    
    <!-- 3. Save updated dialog back to file (chat_dialog is now a JSON string) -->
    <system>mkdir -p ../queues/telegram-dialogs && printf '%s' '<variable name="chat_dialog" />' > "<variable name="dialog_file" />"</system>
    
    <!-- 4. Output reply as DIRAC XML to stdout with CDATA (will be sent to telegram-outgoing queue) -->
    <output>&lt;reply chat_id="<variable name="chat_id"/>"&gt;&lt;![CDATA[<variable name="response"/>]]&gt;&lt;/reply&gt;</output>
  </subroutine>
  
  <!-- Execute the incoming command -->
  <execute><variable name="command"/></execute>
</dirac>
