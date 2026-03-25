<!-- 
  Telegram Worker - Processes messages with LLM
  
  Input format (from queue):
    <message chat_id="123456" text="user message" sender="John" />
  
  Output format (to queue):
    <reply chat_id="123456" text="bot response" />
  
  Dialog Persistence:
  - Loads conversation history from file: ../queues/telegram-dialogs/{chat_id}.json
  - Uses context="chat_dialog" to maintain conversation across messages
  - Saves updated history back to file after each LLM response
-->
<dirac>
  <import src="dirac/lib/native-tags.di" />
  
  <!-- Read message from stdin (provided by queue system) -->
  <defvar name="command"><input source="stdin" mode="all"/></defvar>
  
  <!-- Define message handler -->
  <subroutine name="message" 
              param-chat_id="string:required:Telegram chat ID" 
              param-text="string:required:User message text" 
              param-sender="string:optional:Sender name">
    <!-- 1. Load dialog history from file -->
    <defvar name="dialog_file">../queues/telegram-dialogs/<variable name="chat_id" />.json</defvar>
    <defvar name="chat_dialog">
      <system>cat <variable name="dialog_file" /> 2>/dev/null || echo '[]'</system>
    </defvar>
    
    <!-- 2. Process with LLM (context attribute manages the dialog) -->
    <llm context="chat_dialog" output="response">
      <variable name="text"/>
    </llm>
    
    <!-- 3. Save updated dialog back to file -->
    <system>mkdir -p ../queues/telegram-dialogs && echo '<variable name="chat_dialog" />' > <variable name="dialog_file" /></system>
    
    <!-- 5. Output reply as DIRAC XML to stdout (will be sent to telegram-outgoing queue) -->
    <output>&lt;reply chat_id="<variable name="chat_id"/>" text="<variable name="response"/>" /&gt;</output>
  </subroutine>
  
  <!-- Execute the incoming command -->
  <execute><variable name="command"/></execute>
</dirac>
