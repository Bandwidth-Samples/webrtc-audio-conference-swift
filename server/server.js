const BandwidthWebRTC = require("@bandwidth/webrtc");
const express = require("express");
const uuid = require("uuid");
const dotenv = require("dotenv").config();

const bodyParser = require("body-parser");
const app = express();
app.use(bodyParser.json());
app.use(express.static("public"));

// global vars
const port = process.env.LOCAL_PORT;
const accountId = process.env.BW_ACCOUNT_ID;
var rooms_db = new Map();

BandwidthWebRTC.Configuration.basicAuthUserName = process.env.BW_USERNAME;
BandwidthWebRTC.Configuration.basicAuthPassword = process.env.BW_PASSWORD;
var webRTCController = BandwidthWebRTC.APIController;

app.post("/joinCall", async (req, res) => {
  console.log(`joinCall> about to setup browser client, data: '${req.body}'`);
  console.log(req.body);

  // setup the session and add this user into it
  var room;
  try {
    console.log(`Adding ${req.body.caller.name} to session`);
    var [participant, token] = await createParticipant(
      accountId,
      req.body.audio,
      req.body.video,
      uuid.v1()
    );

    room = await addParticipantToRoom(accountId, participant.id, req.body.room);
  } catch (error) {
    console.log("Failed to start the browser call:", error);
    return res.status(500).send({ message: "failed to set up participant" });
  }

  // now that we have added them to the session,
  //  we can send back the token they need to join
  //  as well as info about the room they are in
  res.send({
    message: "created particpant and setup session",
    token: token,
    room: room,
  });
});

app.listen(port, () => {
  console.log(`Example app listening on port ${port}!`);
});

//
// Calling out to Bandwidth functions
//
/**
 *  Create a new participant
 * @param account_id
 * @param audio_perm boolean for audio permission
 * @param video_perm boolean for video permission
 * @param tag to tag the participant with, no PII should be placed here
 * @return list: (a Participant json object, the participant token)
 */
async function createParticipant(account_id, audio_perm, video_perm, tag) {
  perms = [];
  if (audio_perm) perms.push("AUDIO");
  if (video_perm) perms.push("VIDEO");
  // create a participant for this browser user
  var participantBody = new BandwidthWebRTC.Participant({
    tag: tag,
    publishPermissions: perms,
    deviceApiVersion: 'V3'
  });

  try {
    let createResponse = await webRTCController.createParticipant(
      accountId,
      participantBody
    );

    return [createResponse.participant, createResponse.token];
  } catch (error) {
    console.log("failed to create Participant", error);
    throw new Error(
      "Failed to createParticipant, error from BAND:" + error.errorMessage
    );
  }
}

/**
 * @param account_id The id for this account
 * @param participant_id a Participant id
 * @param room_name The room to add this participant to
 * @return room in case you want any details about the state of the room
 */
async function addParticipantToRoom(account_id, participant_id, room_name) {
  room = await getRoom(accountId, room_name);

  var body = new BandwidthWebRTC.Subscriptions({ sessionId: room.session_id });

  try {
    await webRTCController.addParticipantToSession(
      accountId,
      room.session_id,
      participant_id,
      body
    );
  } catch (error) {
    console.log("Error on addParticipant to Session:", error);
    throw new Error(
      "Failed to addParticipantToSession, error from BAND:" + error.errorMessage
    );
  }

  // update the room with the new participant
  room.participants.push(participant_id);
  rooms_db.set(room_name, room);

  return room;
}

/**
 * Create a room or return it if it's an existing one
 * @param account_id
 * @param room_name the room you are joining
 * @return the room for this session
 */
async function getRoom(account_id, room_name) {
  // check if we've already created a session for this call
  //  - this is a simplification we're doing for this demo
  if (rooms_db.has(room_name)) {
    return rooms_db.get(room_name);
  }

  console.log(`No room/session found, creating '${room_name}'`);
  // otherwise, create the session
  // tags are useful to audit or manage billing records
  let sessionBody = new BandwidthWebRTC.Session({ tag: `demo.${room_name}` });
  let sessionResponse;
  try {
    sessionResponse = await webRTCController.createSession(
      account_id,
      sessionBody
    );
  } catch (error) {
    console.log("getRoom> Failed to create room/session:", error);
    throw new Error(
      "Error in createSession, error from BAND:" + error.errorMessage
    );
  }

  // saves it for future use, this would normally be stored with meeting/call/appt details
  room = {
    name: room_name,
    session_id: sessionResponse.id,
    participants: [],
    calls: [],
  };
  rooms_db.set(room_name, room);

  return room;
}
