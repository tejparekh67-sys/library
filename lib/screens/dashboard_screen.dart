import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_book_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  List books = [];
  List filteredBooks = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadBooks();
  }

  // LOAD BOOKS
  Future<void> loadBooks() async {

    final snapshot =
        await FirebaseFirestore.instance.collection("books").get();

    books = snapshot.docs.map((doc) {
      var data = doc.data();
      data["id"] = doc.id;
      return data;
    }).toList();

    filteredBooks = books;

    setState(() {
      loading = false;
    });
  }

  // DELETE BOOK
  Future<void> deleteBook(int index) async {

    await FirebaseFirestore.instance
        .collection("books")
        .doc(books[index]["id"])
        .delete();

    loadBooks();
  }

  // ISSUE BOOK
  Future<void> toggleIssue(int index) async {

    bool newStatus = !books[index]["issued"];

    await FirebaseFirestore.instance
        .collection("books")
        .doc(books[index]["id"])
        .update({
      "issued": newStatus
    });

    loadBooks();
  }

  // LOGOUT
  Future<void> logout() async {

    await FirebaseAuth.instance.signOut();

    Navigator.pushReplacementNamed(context, "/login");
  }

  // SEARCH
  void searchBook(String value) {

    setState(() {

      filteredBooks = books.where((book) {

        return book["title"]
            .toString()
            .toLowerCase()
            .contains(value.toLowerCase());

      }).toList();

    });
  }

  @override
  Widget build(BuildContext context) {

    final width = MediaQuery.of(context).size.width;

    return Scaffold(

      appBar: AppBar(
        title: const Text("📚 Library Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          )
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, "/addBook");
          loadBooks();
        },
        child: const Icon(Icons.add),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : filteredBooks.isEmpty
          ? const Center(
        child: Text(
          "No Books Available",
          style: TextStyle(fontSize: 18),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(20),

        child: GridView.builder(

          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(

            crossAxisCount: width > 1200
                ? 4
                : width > 900
                ? 3
                : width > 600
                ? 2
                : 1,

            crossAxisSpacing: 15,
            mainAxisSpacing: 15,

            // ✅ FIXED FOR MOBILE
            childAspectRatio: width < 600 ? 1.3 : 2.2,
          ),

          itemCount: filteredBooks.length,

          itemBuilder: (context, i) {

            final b = filteredBooks[i];

            return Container(

              padding: const EdgeInsets.all(15),

              decoration: BoxDecoration(

                color: Colors.blue.shade50,

                borderRadius: BorderRadius.circular(12),

                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 5,
                    offset: const Offset(0,3),
                  )
                ],

              ),

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [

                  /// ✅ BOOK TITLE (FIXED)
                  Text(
                    b["title"] ?? "",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2, // 👈 mobile fix
                    overflow: TextOverflow.ellipsis,
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Author: ${b["author"] ?? ""}"),
                      Text("ISBN: ${b["isbn"] ?? ""}"),
                      Text("Quantity: ${b["quantity"] ?? ""}"),
                    ],
                  ),

                  Wrap(

                    spacing: 5,
                    runSpacing: 5,

                    children: [

                      Container(

                        padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5
                        ),

                        decoration: BoxDecoration(

                          color: b["issued"]
                              ? Colors.red.shade100
                              : Colors.green.shade100,

                          borderRadius: BorderRadius.circular(20),

                        ),

                        child: Text(

                          b["issued"] ? "Issued" : "Available",

                          style: TextStyle(
                            color: b["issued"]
                                ? Colors.red
                                : Colors.green,
                          ),

                        ),

                      ),

                      IconButton(
                        icon: const Icon(Icons.swap_horiz),
                        onPressed: () {
                          toggleIssue(i);
                        },
                      ),

                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {

                          final updated =
                          await Navigator.push(

                            context,

                            MaterialPageRoute(
                              builder: (context) =>
                                  EditBookScreen(
                                    book: b,
                                  ),
                            ),
                          );

                          if(updated != null){
                            loadBooks();
                          }

                        },
                      ),

                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),

                        onPressed: () {
                          deleteBook(i);
                        },
                      ),

                    ],
                  )

                ],
              ),
            );
          },
        ),
      ),
    );
  }
}