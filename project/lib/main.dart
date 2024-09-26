import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Veresiye Defteri',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MainPanel(),
    );
  }
}

// Ana Panel Ekranı
class MainPanel extends StatelessWidget {
  const MainPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Panel'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const VeresiyeDefteriScreen()),
                );
              },
              child: const Text('Veresiye Ekleme Paneli'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const VeresiyeListesiScreen()),
                );
              },
              child: const Text('Veresiyeleri Görme Paneli'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ParaIslemleriPaneli()),
                );
              },
              child: const Text('Para Giriş-Çıkışı Paneli'),
            ),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Günü Bitirme'),
                      content: const Text('Günü bitirmek istediğinizden emin misiniz?'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Gün başarıyla bitirildi!')),
                            );
                          },
                          child: const Text('Evet'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Hayır'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Text('Günü Bitir'),
            ),
          ],
        ),
      ),
    );
  }
}

// Veresiye Ekleme Paneli
class VeresiyeDefteriScreen extends StatefulWidget {
  const VeresiyeDefteriScreen({Key? key}) : super(key: key);

  @override
  _VeresiyeDefteriScreenState createState() => _VeresiyeDefteriScreenState();
}

class _VeresiyeDefteriScreenState extends State<VeresiyeDefteriScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController debtController = TextEditingController();
  final TextEditingController dueDateController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  void addCustomer() {
    Customer newCustomer = Customer(
      name: nameController.text,
      debt: double.parse(debtController.text),
      dueDate: dueDateController.text,
      phoneNumber: phoneController.text,
    );
    DatabaseHelper().insertCustomer(newCustomer.toMap());
    nameController.clear();
    debtController.clear();
    dueDateController.clear();
    phoneController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Veresiye Ekleme Paneli'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'İsim'),
            ),
            TextField(
              controller: debtController,
              decoration: const InputDecoration(labelText: 'Borç Miktarı'),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')), // Sadece sayılar ve en fazla iki ondalık basamağa izin ver
              ],
            ),
            TextField(
              controller: dueDateController,
              decoration: const InputDecoration(labelText: 'Son Ödeme Tarihi (GGAA)'),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly, // Sadece sayılara izin ver
                LengthLimitingTextInputFormatter(4), // En fazla 4 karakter (GGAA formatı için)
              ],
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Telefon Numarası'),
              keyboardType: TextInputType.phone,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly, // Sadece sayılara izin ver
              ],
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: addCustomer,
              child: const Text('Müşteri Ekle'),
            ),
          ],
        ),
      ),
    );
  }
}

// Veresiye Listesi Görüntüleme ve Düzenleme Paneli
class VeresiyeListesiScreen extends StatefulWidget {
  const VeresiyeListesiScreen({Key? key}) : super(key: key);

  @override
  _VeresiyeListesiScreenState createState() => _VeresiyeListesiScreenState();
}

class _VeresiyeListesiScreenState extends State<VeresiyeListesiScreen> {
  List<Customer> customers = [];
  List<Customer> filteredCustomers = [];
  final TextEditingController searchController = TextEditingController();
  final dbHelper = DatabaseHelper();
  String sortColumn = 'name';
  bool isAscending = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  void _loadCustomers() async {
    final allRows = await dbHelper.queryAllCustomers();
    setState(() {
      customers = allRows.map((row) => Customer(
        id: row['id'],
        name: row['name'],
        debt: row['debt'],
        dueDate: row['dueDate'],
        phoneNumber: row['phoneNumber'],
      )).toList();
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      filteredCustomers = customers.where((customer) {
        return customer.name.toLowerCase().contains(searchController.text.toLowerCase());
      }).toList();
      _sortCustomers();
    });
  }

  void _sortCustomers() {
    filteredCustomers.sort((a, b) {
      if (sortColumn == 'name') {
        return isAscending ? a.name.compareTo(b.name) : b.name.compareTo(a.name);
      } else if (sortColumn == 'debt') {
        return isAscending ? a.debt.compareTo(b.debt) : b.debt.compareTo(a.debt);
      } else if (sortColumn == 'dueDate') {
        return isAscending ? a.dueDate.compareTo(b.dueDate) : b.dueDate.compareTo(a.dueDate);
      }
      return 0;
    });
  }

  void _toggleSort(String column) {
    setState(() {
      if (sortColumn == column) {
        isAscending = !isAscending;
      } else {
        sortColumn = column;
        isAscending = true;
      }
      _sortCustomers();
    });
  }

  void _deleteCustomer(int id) async {
    await dbHelper.deleteCustomer(id);
    _loadCustomers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Veresiyeleri Görme Paneli'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Alıcı İsmini Ara',
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                _applyFilters();
              },
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSortButton('İsim', 'name'),
                _buildSortButton('Borç Miktarı', 'debt'),
                _buildSortButton('Son Ödeme Tarihi', 'dueDate'),
              ],
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: ListView.builder(
                itemCount: filteredCustomers.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      title: Text(filteredCustomers[index].name),
                      subtitle: Text(
                        'Borç: ${filteredCustomers[index].debt.toStringAsFixed(2)} TL\n'
                        'Son Ödeme Tarihi: ${filteredCustomers[index].dueDate}\n'
                        'Telefon: ${filteredCustomers[index].phoneNumber}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          _deleteCustomer(filteredCustomers[index].id!);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortButton(String title, String column) {
    return InkWell(
      onTap: () => _toggleSort(column),
      child: Row(
        children: [
          Text(title),
          Icon(
            isAscending && sortColumn == column ? Icons.arrow_upward : Icons.arrow_downward,
          ),
        ],
      ),
    );
  }
}

// Para Giriş-Çıkış ve Bakiye Takip Paneli
class ParaIslemleriPaneli extends StatefulWidget {
  const ParaIslemleriPaneli({Key? key}) : super(key: key);

  @override
  _ParaIslemleriPaneliState createState() => _ParaIslemleriPaneliState();
}

class _ParaIslemleriPaneliState extends State<ParaIslemleriPaneli> {
  double balance = 1000.0; // Başlangıç Bakiyesi
  final TextEditingController amountController = TextEditingController();

  void _addBalance() {
    setState(() {
      balance += double.tryParse(amountController.text) ?? 0.0;
    });
    amountController.clear();
  }

  void _subtractBalance() {
    setState(() {
      balance -= double.tryParse(amountController.text) ?? 0.0;
    });
    amountController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Para Giriş-Çıkış Paneli'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Mevcut Bakiye: ${balance.toStringAsFixed(2)} TL',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Tutar Girin'),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')), // Sadece sayılar ve en fazla iki ondalık basamağa izin ver
              ],
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _addBalance,
                  child: const Text('Para Girişi'),
                ),
                const SizedBox(width: 16.0),
                ElevatedButton(
                  onPressed: _subtractBalance,
                  child: const Text('Para Çıkışı'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Customer Sınıfı
class Customer {
  int? id;
  String name;
  double debt;
  String dueDate;
  String phoneNumber;

  Customer({this.id, required this.name, required this.debt, required this.dueDate, required this.phoneNumber});

  // Müşteriyi map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'debt': debt,
      'dueDate': dueDate,
      'phoneNumber': phoneNumber,
    };
  }
}
