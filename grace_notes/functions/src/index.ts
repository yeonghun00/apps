import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

interface CommentData {
  postId: string;
  postTitle: string;
  authorId: string;
  authorName: string;
  content: string;
  createdAt: admin.firestore.Timestamp;
}

interface PostData {
  title: string;
  authorId: string;
  type: 'general' | 'question' | 'testimony' | 'prayer';
}

interface UserData {
  fcmToken?: string;
  displayName?: string;
  notificationsEnabled?: boolean;
}

export const onCommentCreated = functions.firestore
  .document('community_posts/{postId}/comments/{commentId}')
  .onCreate(async (snap, context) => {
    try {
      const commentData = snap.data() as CommentData;
      const postId = context.params.postId;

      // Get the post data to find the post author
      const postDoc = await admin.firestore()
        .collection('community_posts')
        .doc(postId)
        .get();

      if (!postDoc.exists) {
        console.log('Post not found:', postId);
        return;
      }

      const postData = postDoc.data() as PostData;
      const postAuthorId = postData.authorId;

      // Don't send notification if the comment author is the same as post author
      if (commentData.authorId === postAuthorId) {
        console.log('Comment author is the same as post author, skipping notification');
        return;
      }

      // Get the post author's user data to check notifications setting and FCM token
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(postAuthorId)
        .get();

      if (!userDoc.exists) {
        console.log('Post author user not found:', postAuthorId);
        return;
      }

      const userData = userDoc.data() as UserData;

      // Check if notifications are enabled for this user
      if (userData.notificationsEnabled === false) {
        console.log('Notifications disabled for user:', postAuthorId);
        return;
      }

      // Check if user has FCM token
      if (!userData.fcmToken) {
        console.log('No FCM token for user:', postAuthorId);
        return;
      }

      // Prepare notification payload
      const title = '새 댓글';
      const body = `${commentData.authorName}님이 "${postData.title}"에 댓글을 남겼습니다`;

      const message = {
        token: userData.fcmToken,
        notification: {
          title: title,
          body: body,
        },
        data: {
          postId: postId,
          commentId: snap.id,
          type: 'comment',
        },
        android: {
          notification: {
            icon: '@mipmap/ic_launcher',
            color: '#9B7EBD', // AppTheme.primaryPurple
            channelId: 'comments',
          },
        },
        apns: {
          payload: {
            aps: {
              badge: 1,
              sound: 'default',
            },
          },
        },
      };

      // Send the notification
      const response = await admin.messaging().send(message);
      console.log('Successfully sent notification:', response);

    } catch (error) {
      console.error('Error sending notification:', error);
    }
  });

// Function to clean up invalid FCM tokens
export const cleanupInvalidTokens = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  try {
    // This function can be called periodically to clean up invalid tokens
    // For now, it's just a placeholder
    console.log('Cleanup function called');
    return { success: true };
  } catch (error) {
    console.error('Error in cleanup function:', error);
    throw new functions.https.HttpsError('internal', 'Internal error');
  }
});