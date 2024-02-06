import 'package:flutter/material.dart';
import 'package:flutter_toastr/flutter_toastr.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';


void main() {
  runApp(MyApp());
}

class Contact {
  String name;
  String phoneNumber;

  Contact({required this.name, required this.phoneNumber});

  // Convert a Contact object to a Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
    };
  }

  // Convert a Map to a Contact object
  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      name: map['name'],
      phoneNumber: map['phoneNumber'],
    );
  }

  // Convert a Contact object to a JSON string
  String toJson() => json.encode(toMap());

  // Convert a JSON string to a Contact object
  factory Contact.fromJson(String source) =>
      Contact.fromMap(json.decode(source));
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Phonebook App',
      home: PhonebookScreen(),
      theme: ThemeData(
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.purpleAccent,
          foregroundColor: Colors.black,
          hoverColor: Colors.deepPurple,
          splashColor: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          color: Colors.purpleAccent,
        ),
      ),
    );
  }
}

class PhonebookScreen extends StatefulWidget {
  @override
  _PhonebookScreenState createState() => _PhonebookScreenState();
}

class _PhonebookScreenState extends State<PhonebookScreen> {
  List<Contact> contacts = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load contacts from local storage when the screen is initialized
    loadContacts();
  }

  void loadContacts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? contactsData = prefs.getStringList('contacts');

    if (contactsData != null) {
      setState(() {
        contacts = contactsData
            .map((contact) => Contact.fromJson(contact))
            .toList();
      });
    }
  }

  void saveContacts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> contactsData =
    contacts.map((contact) => contact.toJson()).toList();

    prefs.setStringList('contacts', contactsData);
  }

  void addContact(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddContactScreen(),
      ),
    );

    if (result != null && result is Contact) {
      setState(() {
        contacts.add(result);
        contacts.sort((a, b) => a.name.compareTo(b.name));
        saveContacts(); // Save contacts to local storage
      });
    }
  }

  List<Contact> searchContacts(String query) {
    List<Contact> filteredContacts = contacts
        .where((contact) =>
    contact.name.toLowerCase().contains(query.toLowerCase()) ||
        contact.phoneNumber.contains(query))
        .toList();

    filteredContacts.sort((a, b) => a.name.compareTo(b.name));

    return filteredContacts;
  }

  void viewContactDetails(Contact contact) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactDetailsScreen(contact),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Phonebook App'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(labelText: 'Search'),
              onChanged: (query) {
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: contacts.isEmpty
                ? Center(
              child: Text('No contacts saved'),
            )
                : ListView.builder(
              itemCount: searchContacts(searchController.text).length,
              itemBuilder: (context, index) {
                Contact contact =
                searchContacts(searchController.text)[index];
                return ListTile(
                  title: Text(contact.name),
                  subtitle: Text(contact.phoneNumber),
                  onTap: () => viewContactDetails(contact),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => addContact(context),
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddContactScreen extends StatefulWidget {
  @override
  _AddContactScreenState createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();

  void showEmptyFieldsToast() {
    FlutterToastr.show(
      "Both Name and Phone Number are needed to add a contact",
      context,
      duration: FlutterToastr.lengthLong,
      position: FlutterToastr.bottom,
      backgroundColor: Colors.deepPurpleAccent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Contact'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: phoneNumberController,
              decoration: InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty ||
                    phoneNumberController.text.isEmpty) {
                  showEmptyFieldsToast();
                } else {
                  Navigator.pop(
                    context,
                    Contact(
                      name: nameController.text,
                      phoneNumber: phoneNumberController.text,
                    ),
                  );
                }
              },
              child: Text('Add Contact'),
            ),
          ],
        ),
      ),
    );
  }
}

class ContactDetailsScreen extends StatefulWidget {
  final Contact contact;

  ContactDetailsScreen(this.contact);

  @override
  _ContactDetailsScreenState createState() => _ContactDetailsScreenState();
}

class _ContactDetailsScreenState extends State<ContactDetailsScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    nameController.text = widget.contact.name;
    phoneNumberController.text = widget.contact.phoneNumber;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contact Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              _editContact(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
              readOnly: true,
            ),
            SizedBox(height: 16),
            TextField(
              controller: phoneNumberController,
              decoration: InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
              readOnly: true,
            ),
          ],
        ),
      ),
    );
  }

  void _editContact(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditContactScreen(widget.contact),
      ),
    );

    if (result != null && result is Contact) {
      setState(() {
        widget.contact.name = result.name;
        widget.contact.phoneNumber = result.phoneNumber;
      });
    }
  }
}

class EditContactScreen extends StatefulWidget {
  final Contact contact;

  EditContactScreen(this.contact);

  @override
  _EditContactScreenState createState() => _EditContactScreenState();
}

class _EditContactScreenState extends State<EditContactScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    nameController.text = widget.contact.name;
    phoneNumberController.text = widget.contact.phoneNumber;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Contact'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: phoneNumberController,
              decoration: InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  Contact(
                    name: nameController.text,
                    phoneNumber: phoneNumberController.text,
                  ),
                );
              },
              child: Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
