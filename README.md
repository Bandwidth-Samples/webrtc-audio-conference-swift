# WebRTC Audio Conference
<a href="http://dev.bandwidth.com"><img src="https://s3.amazonaws.com/bwdemos/BW-VMP.png"/></a>
</div>

 # Table of Contents

<!-- TOC -->

- [WebRTC Audio Conference](#webrtc-audio-conference)
- [Description](#description)
- [Bandwidth](#bandwidth)
- [Environmental Variables](#environmental-variables)
- [Callback URLs](#callback-urls)
    - [Ngrok](#ngrok)

<!-- /TOC -->

# Description
This sample allows for iOS devices to create a conference call using WebRTC audio.

# Setup

In order to run this sample `WebRTC Audio` is required to be enabled on your account. Please check with your account manager to ensure you are properly provisioned.

## Configure your HTTP server

Copy the default configuration file `.env.default` to `.env`.

```bash
cp .env.default .env
```

Add your Bandwidth account settings to the new configuration file `.env`.

Bandwidth account credentials
- BW_ACCOUNT_ID
- BW_USERNAME
- BW_PASSWORD

Install server dependencies and run.

```bash
npm install
node server.js
```

## Configure your iOS project

Open the `WebRTCAudioConferenceStoyboard` project in Xcode.

Add a property list file `Config.plist` to your project. This should be added to the `WebRTCAudioConferenceStoryboard` folder alongside `Info.plist`.

Add a row to the `Config.plist` property list file with a key `Address` and type `String`. Set the value of the row to the server application address which is accessible to the iOS devices. An ngrok url works well for this.

With the server project running build and run the iOS project on your device from Xcode.

While the device is running the app tap `Connect`. Permissions to your microphone may need to be granted at this time. Once connected tap the large green button to start your phone call.

# Bandwidth

In order to use the Bandwidth API users need to set up the appropriate application at the [Bandwidth Dashboard](https://dashboard.bandwidth.com/) and create API credentials.

To create an application log into the [Bandwidth Dashboard](https://dashboard.bandwidth.com/) and navigate to the `Applications` tab.  Fill out the **New Application** form selecting the service (Messaging or Voice) that the application will be used for.  All Bandwidth services require publicly accessible Callback URLs, for more information on how to set one up see [Callback URLs](#callback-urls).

For more information about API credentials see [here](https://dev.bandwidth.com/guides/accountCredentials.html#top)

# Environmental Variables
The sample app uses the below environmental variables.
```sh
BW_ACCOUNT_ID                 # Your Bandwidth Account Id
BW_USERNAME                   # Your Bandwidth API Username
BW_PASSWORD                   # Your Bandwidth API Password
```

## Ngrok

A simple way to set up a local callback URL for testing is to use the free tool [ngrok](https://ngrok.com/).  
After you have downloaded and installed `ngrok` run the following command to open a public tunnel to your port (`$LOCAL_PORT`)
```cmd
ngrok http $LOCAL_PORT
```
You can view your public URL at `http://127.0.0.1:{LOCAL_PORT}` after ngrok is running.  You can also view the status of the tunnel and requests/responses here.
