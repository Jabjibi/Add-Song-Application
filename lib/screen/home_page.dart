import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[
    BrowsePage(),
    Center(child: Text('Library Page')), // Placeholder for Library
    Center(child: Text('Search Page')), // Placeholder for Search
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _addNewSong() {
    TextEditingController songNameController = TextEditingController();
    TextEditingController singerNameController = TextEditingController();
    TextEditingController imageUrlController = TextEditingController();
    TextEditingController typeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Song'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: imageUrlController,
                decoration: InputDecoration(labelText: 'Image URL'),
              ),
              TextField(
                controller: songNameController,
                decoration: InputDecoration(labelText: 'Song Name'),
              ),
              TextField(
                controller: singerNameController,
                decoration: InputDecoration(labelText: 'Singer Name'),
              ),
              TextField(
                controller: typeController,
                decoration: InputDecoration(labelText: 'Type'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (imageUrlController.text.isEmpty ||
                    songNameController.text.isEmpty ||
                    singerNameController.text.isEmpty ||
                    typeController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please fill all fields')));
                  return;
                }

                await FirebaseFirestore.instance.collection('Songs').add({
                  'image_song': imageUrlController.text,
                  'song_name': songNameController.text,
                  'singer_name': singerNameController.text,
                  'type_song': typeController.text,
                });

                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Song added successfully')));
                Navigator.pop(context);
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_circle, size: 35), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        ],
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 1) {
            _addNewSong();
          } else {
            _onItemTapped(index);
          }
        },
      ),
    );
  }
}

class BrowsePage extends StatefulWidget {
  @override
  _BrowsePageState createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  final CollectionReference songs =
      FirebaseFirestore.instance.collection('Songs');

  void _editSong(DocumentSnapshot doc) {
    TextEditingController songNameController =
        TextEditingController(text: doc['song_name']);
    TextEditingController singerNameController =
        TextEditingController(text: doc['singer_name']);
    TextEditingController imageUrlController =
        TextEditingController(text: doc['image_song']);
    TextEditingController typeController =
        TextEditingController(text: doc['type_song']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Song'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: imageUrlController,
                  decoration: InputDecoration(labelText: 'Image URL')),
              TextField(
                  controller: songNameController,
                  decoration: InputDecoration(labelText: 'Song Name')),
              TextField(
                  controller: singerNameController,
                  decoration: InputDecoration(labelText: 'Singer Name')),
              TextField(
                  controller: typeController,
                  decoration: InputDecoration(labelText: 'Type')),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await songs.doc(doc.id).update({
                  'image_song': imageUrlController.text,
                  'song_name': songNameController.text,
                  'singer_name': singerNameController.text,
                  'type_song': typeController.text,
                });
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteSong(String docId) async {
    await songs.doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Browse',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset("assets/images/songs.png"),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Trending Song",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: songs.snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No songs available'));
                }
                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    return ListTile(
                      leading: Image.network(doc['image_song'],
                          width: 50, height: 50, fit: BoxFit.cover),
                      title: Text(doc['song_name'],
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(doc['singer_name']),
                      trailing: PopupMenuButton(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editSong(doc);
                          } else if (value == 'delete') {
                            _deleteSong(doc.id);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
