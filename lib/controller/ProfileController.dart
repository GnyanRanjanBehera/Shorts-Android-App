import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tiktok/controller/AuthController.dart';
class ProfileController extends GetxController{
  final Rx<Map<String,dynamic>> _user=Rx<Map<String,dynamic>>({});

  Map<String,dynamic> get user=>_user.value;

  final Rx<String> _uid="".obs;

  updateUserId(String uid){
    _uid.value=uid;
    getUser();
  }

  getUser()async{
    List<String> thumbnails=[];
    var myVideos=await FirebaseFirestore.instance.collection("videos").where("uid",isEqualTo: _uid.value).get();
    for(int i=0;i<myVideos.docs.length;i++){
      thumbnails.add((myVideos.docs[i].data() as dynamic)['thumbnail']);
    }
    DocumentSnapshot userDoc=await FirebaseFirestore.instance.collection("users").doc(_uid.value).get();
    final userData=userDoc.data() as dynamic;
    String name=userDoc['name'];
    String profilePhoto=userDoc['profilePhoto'];
    int likes=0;
    int followers=0;
    int followings=0;
    bool isFollowing=false;
    for(var item in myVideos.docs){
      likes+=(item.data()['likes'] as List).length;
    }
    var followerDoc=await FirebaseFirestore.instance.collection("users").doc(_uid.value).collection("followers").get();
    var followingDoc=await FirebaseFirestore.instance.collection("users").doc(_uid.value).collection("followings").get();

    followers=followerDoc.docs.length;
    followings=followingDoc.docs.length;

    FirebaseFirestore.instance.collection("users").doc(_uid.value).collection("followers").doc(FirebaseAuth.instance.currentUser!.uid).get().then((value){
      if(value.exists){
        isFollowing=true;
      }else{
        isFollowing=false;
      }
    });
    _user.value={
      "followers":followers.toString(),
      "followings":followings.toString(),
      "likes":likes.toString(),
      "profilePhoto":profilePhoto,
      "name":name,
      "isFollowing":isFollowing,
      "thumbnails":thumbnails
    };
    update();
  }
  followUser()async{
    var doc=await FirebaseFirestore.instance.collection("users").doc(_uid.value).collection('followers').doc(FirebaseAuth.instance.currentUser!.uid).get();
    if(!doc.exists){
      await FirebaseFirestore.instance.collection("users").doc(_uid.value).collection("followers").doc(FirebaseAuth.instance.currentUser!.uid).set({});
      await FirebaseFirestore.instance.collection("users").doc(FirebaseAuth.instance.currentUser!.uid).collection("followings").doc(_uid.value).set({});
      _user.value.update('followers', (value) => (int.parse(value)+1).toString());
    }else{
      await FirebaseFirestore.instance.collection("users").doc(_uid.value).collection("followers").doc(FirebaseAuth.instance.currentUser!.uid).delete();
      await FirebaseFirestore.instance.collection("users").doc(FirebaseAuth.instance.currentUser!.uid).collection("followings").doc(_uid.value).delete();
      _user.value.update('followers', (value) => (int.parse(value)-1).toString());
    }
    _user.value.update('isFollowing', (value) => !value);
    update();
  }

}