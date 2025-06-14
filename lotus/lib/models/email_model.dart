import 'package:flutter/material.dart';
import 'package:lotus/models/user_model.dart';

class Email {
  final User sender;
  final String time;
  final String text;
  final String subject;

  Email({
    required this.sender,
    required this.time,
    required this.text,
    required this.subject,
  });
}

// Placeholder
final User currentUser =User(id: 0, name: 'Deepa Pandey', imageUrl: Colors.red);
final User linkedln = User(id: 1, name: 'Linkedln', imageUrl: Colors.orange);
final User sugar = User(id: 2, name: 'Sugar Cosmetics', imageUrl: Colors.grey);
final User medium = User(id: 3, name: 'Medium Daily', imageUrl: Colors.deepPurpleAccent);
final User amazon = User(id: 4, name: 'Amazon.in', imageUrl: Colors.yellow);
final User deepak = User(id: 5, name: 'Deepak Pandey', imageUrl: Colors.red);
final User balram = User(id: 6, name: 'Balram Rathore', imageUrl:Colors.teal);
final User leetcode = User(id: 7, name: 'LeetCode', imageUrl: Colors.blueGrey);
final User digitalocean = User(id: 8, name: 'Digital Ocean', imageUrl: Colors.deepPurpleAccent);
final User digitalocean1 = User(id: 9, name: 'Digital Ocean', imageUrl: Colors.greenAccent);
final User digitalocean2 = User(id: 10, name: 'Digital Ocean', imageUrl: Colors.lightBlue);
final User digitalocean3 = User(id: 11, name: 'Digital Ocean', imageUrl: Colors.amber);
final User digitalocean4 = User(id: 12, name: 'Digital Ocean', imageUrl: Colors.greenAccent);

List<Email> mails = [
  Email(
    sender: linkedln,
    time: '10:30 PM',
    text: 'View jobs in Bengaluru, Karnataka, India, match your preferences, Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
    subject: '11 new jobs for "Full Stack Engineers" ',
  ),
  Email(
    sender: sugar,
    time: '9:55 PM',
    text: 'Get the best ❤️red❤️ mini Lipstick💄 Set at a complete 25% discount...Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
    subject: 'Limited-edition V-day 💄',
  ),
  Email(
    sender: medium,
    time: '9:05 PM',
    text: 'Stories for Deepa Pandey : How I got an engineering internships in...Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
    subject: 'Simple SQFlite databases examples in flutter',
  ),
  Email(
    sender: amazon,
    time: '8:30 PM',
    text: 'Amazon Orders|1 of 5 items order has been dispatched...Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
    subject: 'Your Amazon.in order #205-304458 of 1 item has been dispatched',
  ),
  Email(
    sender: deepak,
    time: 'Feb 12',
    text: 'Check the modified PDF attached & send feedback...Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
    subject: 'PDF attached',
  ),
  Email(
    sender: balram,
    time: 'Feb 12',
    text: 'Ive created the collab repo, shall we start making the project?...Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
    subject: 'Invitation to github collaborator',
  ),
  Email(
    sender: leetcode,
    time: 'Feb 11',
    text: 'Hello!🎉 Congratulations to our 1st leetcodes Pick winner...Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
    subject: 'Leetcode Weekly Digest',
  ),
  Email(
    sender: digitalocean,
    time: 'Feb 10',
    text: 'Get your Dev Badge at Hacktoberfest ,just by login into the Dev Website...Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. ',
    subject: 'Dev Badge @Hacktoberfest',
  ),
  Email(
    sender: digitalocean1,
    time: 'Feb 10',
    text: 'Get your Dev Badge at Hacktoberfest ,just by login into the Dev Website...Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. ',
    subject: 'Dev Badge @Hacktoberfest',
  ),
  Email(
    sender: digitalocean2,
    time: 'Feb 10',
    text: 'Get your Dev Badge at Hacktoberfest ,just by login into the Dev Website...Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. ',
    subject: 'Dev Badge @Hacktoberfest',
  ),
  Email(
    sender: digitalocean3,
    time: 'Feb 10',
    text: 'Get your Dev Badge at Hacktoberfest ,just by login into the Dev Website...Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. ',
    subject: 'Dev Badge @Hacktoberfest',
  ),
  Email(
    sender: digitalocean4,
    time: 'Feb 10',
    text: 'Get your Dev Badge at Hacktoberfest ,just by login into the Dev Website...Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. ',
    subject: 'Dev Badge @Hacktoberfest',
  ),
];

