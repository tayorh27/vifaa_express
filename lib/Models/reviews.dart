class Reviews {

  String id,username,user_email,avatar,comment,date,rate_star;

  Reviews.fromJson(var snapshot) {
    id = snapshot['id'];
    username = snapshot['username'];
    user_email = snapshot['user_email'];
    avatar = snapshot['avatar'];
    comment = snapshot['comment'];
    date = snapshot['date'];
    rate_star = snapshot['rate_star'];
  }
}