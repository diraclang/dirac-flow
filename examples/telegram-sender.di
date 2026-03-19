<!-- 
  Telegram Sender Worker - Sends messages back to Telegram
  
  Input format (from telegram-outgoing queue):
    <reply chat_id="123456" text="bot response" />
-->
<dirac>
  <import src="../../dirac-stdlib/lib/telegram.di" />
  
  <!-- Get bot token from environment -->
  <defvar name="bot_token" trim="true"><environment name="TELEGRAM_BOT_TOKEN" /></defvar>
  
  <!-- Read reply command from stdin -->
  <input name="command" source="stdin" mode="all"/>
  
  <!-- Define reply handler -->
  <subroutine name="reply" 
              param-chat_id="string:required:Telegram chat ID to send message to" 
              param-text="string:required:Message text to send">
    <!-- Send message to Telegram -->
    <send-telegram-message
      token="$bot_token"
      chat_id="$chat_id"
      message="$text" />
    
    <output>✅ Sent to chat <variable name="chat_id"/></output>
  </subroutine>
  
  <!-- Execute the incoming reply command -->
  <execute><variable name="command"/></execute>
</dirac>
