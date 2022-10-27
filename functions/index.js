const functions = require('firebase-functions');

const admin = require('firebase-admin');
admin.initializeApp(functions.config().firebase);

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions

exports.observeComments = functions.database.ref('/comments/{postId}/{commentId}').onCreate((snapshot, context) => {
  var postId = context.params.postId;
  var commentId = context.params.commentId
  
  return admin.database().ref('/comments/' + postId + '/' + commentId).once('value', snapshot => {
    var comment = snapshot.val();
    var commentUid = comment.uid;
    // console.log('commentUid: ' + commentUid);

    return admin.database().ref('/users/' + commentUid).once('value', snapshot => {
      var commentingUser = snapshot.val();
      var username = commentingUser.username;
      // console.log('username: ' + username);

      return admin.database().ref('/posts/' + postId).once('value', snapshot => {
        var post = snapshot.val();
        var postOwnerUid = post.ownerUid;
        // console.log('postOwnerUid: ' + postOwnerUid);

        return admin.database().ref('/users/' + postOwnerUid).once('value', snapshot => {
          var postOwner = snapshot.val();
          // console.log('postOwnerToken: ' + postOwner.fcmToken);

          var payload = {
            notification: {
            body: username + ' commented on your post'
            },
            token: postOwner.fcmToken
          };

          admin.messaging().send(payload)
          .than(function(response) {
          console.log('Successfully send: ', respone)
          })
          .catch(function(error) {
          console.log('Send Error: ', error)
          });
        })
      })
    })
  })
})

exports.observeLikes = functions.database.ref('/user-like/{uid}/{postId}').onCreate((snapshot, context) => {
  var uid = context.params.uid;
  var postId = context.params.postId;

  return admin.database().ref('/users/' + uid).once('value', snapshot => {
    var userThatLikedPost = snapshot.val();

    return admin.database().ref('/posts/' + postId).once('value', snapshot => {
      var post = snapshot.val();

      return admin.database().ref('/users/' + post.ownerUid).once('value', snapshot => {
        var postOwner = snapshot.val();

        var payload = {
          notification: {
          body: userThatLikedPost.username + ' liked your post'
          },
          token: postOwner.fcmToken
        };

        admin.messaging().send(payload)
        .than(function(response) {
        console.log('Successfully send: ', respone)
        })
        .catch(function(error) {
        console.log('Send Error: ', error)
        });
      })
    })
  })
});

exports.observeFollow = functions.database.ref('/user-following/{uid}/{followedUid}').onCreate((snapshot, context) => {
  var uid = context.params.uid;
  var followedUid = context.params.followedUid;

  return admin.database().ref('/users/' + followedUid).once('value', snapshot => {
    var userThatWasFollowed = snapshot.val();

    return admin.database().ref('/users/' + uid).once('value', snapshot => {
      var userThatFollowed = snapshot.val();

      var payload = {
        notification: {
        title: 'New Follower!',
        body: userThatFollowed.username + ' started following you'
        },
        token: userThatWasFollowed.fcmToken
      };

      admin.messaging().send(payload)
      .than(function(response) {
      console.log('Successfully send: ', respone)
      })
      .catch(function(error) {
      console.log('Send Error: ', error)
      });
    })
  })
});

exports.helloWorld = functions.https.onRequest((request, response) => {
  functions.logger.info("Hello logs!", {structuredData: true});
  response.send("Hello from Firebase!");
});

exports.sendPushNotification = functions.https.onRequest((req, res) => {

  res.send("Attempting to send push notifications")
  console.log("LOGGER --- Trying to send push message..")

  var uid = '3kJkNVVHIgSAfYvtdamJvobLqMu2'

  var fcmToken = 'dRFF_kKs3kPIriOH2YfaV7:APA91bHZ4LSSwHlaCQuMMTtpKi_ELjDJe_5dn47jvD0efm9nu-cc87ybV8WccI79RQFqZr0Vr_5ve6v_G2HjKSq1NfP-HNtxfR4oi5ZztXLx-UnhaZUboRhM5KpXGTdp65BQQ8KZVoUB'

 return admin.database().ref('/users/' + uid).once('value', snapshot => {
   var user = snapshot.val();

   console.log("Username is " + user.username)

     var payload = {
       notification: {
       title: 'Push Notification Title',
       body: 'Test notification message'
       }
     };

     admin.massaging().sendToDevice(fcmToken, payload)
     .than(function(response) {
     console.log('Successfully send to message:', respone)
     })
     .catch(function(error) {
     console.log('Error sending message:', error)
     });
  })
})
