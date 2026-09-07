<!-- 
  Telegram Sender Worker - Sends messages back to Telegram
  
  Input format (from telegram-outgoing queue):
    <reply chat_id="123456"><![CDATA[bot response text]]></reply>
-->
<dirac>
  <import src="dirac-stdlib/lib/telegram.di" />
  
  <!-- Get bot token from environment -->
  <defvar name="bot_token" trim="true"><environment name="TELEGRAM_BOT_TOKEN" /></defvar>
  
  <!-- Read reply command from stdin -->
  <defvar name="command"><input source="stdin" mode="all"/></defvar> 
  
  <!-- Define reply handler - message content comes from text content, not attribute -->
  <subroutine name="reply" 
              param-chat_id="string:required:Telegram chat ID to send message to">
    <!-- Get the message content from subroutine body using parameters select -->
    <defvar name="message_text"><parameters select="*" /></defvar>
    <defvar name="chat_id_trim" trim="true"><variable name="chat_id" /></defvar>
    
    <!-- Send message to Telegram -->
    <send-telegram-message
      token="$bot_token"
      chat_id="$chat_id_trim"
      message="$message_text" />
    
    <output>✅ Sent to chat <variable name="chat_id"/>: <variable name="message_text" /></output>
  </subroutine>
  
  <!-- Execute the incoming reply command -->
 <execute><variable name="command"/></execute> 
</dirac>
