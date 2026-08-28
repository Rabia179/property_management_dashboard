import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const PropertyApp());
}

class PropertyApp extends StatelessWidget {
  const PropertyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Property Management Dashboard',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF101815),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD6A84F),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF101815),
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1A2520),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

// ================= MODEL =================

class Property {
  String id;
  String name;
  String type;
  String location;
  String tenant;
  String phone;
  String status;
  double rent;
  bool rentPaid;

  Property({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
    required this.tenant,
    required this.phone,
    required this.status,
    required this.rent,
    this.rentPaid = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'location': location,
      'tenant': tenant,
      'phone': phone,
      'status': status,
      'rent': rent,
      'rentPaid': rentPaid,
    };
  }

  factory Property.fromJson(Map<String, dynamic> j) {
    return Property(
      id: j['id'] ?? '',
      name: j['name'] ?? '',
      type: j['type'] ?? 'Apartment',
      location: j['location'] ?? '',
      tenant: j['tenant'] ?? '',
      phone: j['phone'] ?? '',
      status: j['status'] ?? 'Available',
      rent: (j['rent'] as num?)?.toDouble() ?? 0,
      rentPaid: j['rentPaid'] ?? false,
    );
  }
}

// ================= STORAGE =================

class Storage {
  static const String key = 'property_dashboard_data';

  static Future<List<Property>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(key);

    if (data == null || data.isEmpty) {
      return [];
    }

    try {
      final list = jsonDecode(data) as List;
      return list
          .map((e) => Property.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<Property> items) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      key,
      jsonEncode(
        items.map((e) => e.toJson()).toList(),
      ),
    );
  }
}

// ================= HOME =================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;
  bool loading = true;
  List<Property> properties = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final saved = await Storage.load();

    if (saved.isEmpty) {
      properties = [
        Property(
          id: 'P1001',
          name: 'Green View Apartment',
          type: 'Apartment',
          location: 'Islamabad',
          tenant: 'Ayesha Khan',
          phone: '03001234567',
          status: 'Rented',
          rent: 45000,
          rentPaid: true,
        ),
        Property(
          id: 'P1002',
          name: 'City Heights',
          type: 'House',
          location: 'Lahore',
          tenant: '',
          phone: '',
          status: 'Available',
          rent: 65000,
        ),
        Property(
          id: 'P1003',
          name: 'Business Plaza',
          type: 'Commercial',
          location: 'Karachi',
          tenant: 'Tech Solutions',
          phone: '03111234567',
          status: 'Rented',
          rent: 90000,
          rentPaid: false,
        ),
      ];

      await Storage.save(properties);
    } else {
      properties = saved;
    }

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  Future<void> save() async {
    await Storage.save(properties);

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final pages = [
      DashboardPage(properties: properties),
      PropertiesPage(
        properties: properties,
        onChanged: save,
        onAdd: propertyDialog,
      ),
      TenantsPage(
        properties: properties,
        onChanged: save,
      ),
      RentPage(
        properties: properties,
        onChanged: save,
      ),
      ReportsPage(
        properties: properties,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          [
            'Property Dashboard',
            'Properties',
            'Tenants',
            'Rent',
            'Reports',
          ][index],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No new notifications'),
                ),
              );
            },
            icon: const Icon(Icons.notifications_none),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundColor: Color(0xFFD6A84F),
              foregroundColor: Colors.black,
              child: Icon(Icons.person),
            ),
          ),
        ],
      ),
      body: pages[index],
      floatingActionButton: index == 1
          ? FloatingActionButton.extended(
        onPressed: propertyDialog,
        backgroundColor: const Color(0xFFD6A84F),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_home),
        label: const Text('Add Property'),
      )
          : null,
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF17211D),
        indicatorColor: const Color(0xFFD6A84F),
        selectedIndex: index,
        onDestinationSelected: (value) {
          setState(() {
            index = value;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_work_outlined),
            selectedIcon: Icon(Icons.home_work),
            label: 'Properties',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Tenants',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: 'Rent',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
        ],
      ),
    );
  }

  Future<void> propertyDialog([Property? item]) async {
    final name = TextEditingController(text: item?.name ?? '');
    final location = TextEditingController(text: item?.location ?? '');
    final tenant = TextEditingController(text: item?.tenant ?? '');
    final phone = TextEditingController(text: item?.phone ?? '');
    final rent = TextEditingController(
      text: item?.rent.toString() ?? '',
    );

    String type = item?.type ?? 'Apartment';
    String status = item?.status ?? 'Available';

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialog) {
            return AlertDialog(
              title: Text(
                item == null ? 'Add Property' : 'Edit Property',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: name,
                      decoration: const InputDecoration(
                        labelText: 'Property Name',
                      ),
                    ),
                    TextField(
                      controller: location,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                      ),
                    ),
                    TextField(
                      controller: tenant,
                      decoration: const InputDecoration(
                        labelText: 'Tenant',
                      ),
                    ),
                    TextField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Tenant Phone',
                      ),
                    ),
                    TextField(
                      controller: rent,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Monthly Rent',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: const InputDecoration(
                        labelText: 'Property Type',
                      ),
                      items: const [
                        'Apartment',
                        'House',
                        'Commercial',
                        'Office',
                      ]
                          .map(
                            (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ),
                      )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialog(() {
                            type = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                      ),
                      items: const [
                        'Available',
                        'Rented',
                        'Maintenance',
                      ]
                          .map(
                            (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ),
                      )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialog(() {
                            status = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (name.text.trim().isEmpty) {
                      return;
                    }

                    if (item == null) {
                      properties.add(
                        Property(
                          id: 'P${DateTime.now().millisecondsSinceEpoch}',
                          name: name.text.trim(),
                          type: type,
                          location: location.text.trim(),
                          tenant: tenant.text.trim(),
                          phone: phone.text.trim(),
                          status: status,
                          rent: double.tryParse(rent.text) ?? 0,
                        ),
                      );
                    } else {
                      item.name = name.text.trim();
                      item.type = type;
                      item.location = location.text.trim();
                      item.tenant = tenant.text.trim();
                      item.phone = phone.text.trim();
                      item.status = status;
                      item.rent =
                          double.tryParse(rent.text) ?? item.rent;
                    }

                    await save();

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    name.dispose();
    location.dispose();
    tenant.dispose();
    phone.dispose();
    rent.dispose();
  }
}

// ================= DASHBOARD =================

class DashboardPage extends StatelessWidget {
  final List<Property> properties;

  const DashboardPage({
    super.key,
    required this.properties,
  });

  @override
  Widget build(BuildContext context) {
    final total = properties.length;

    final rented = properties
        .where((p) => p.status == 'Rented')
        .length;

    final available = properties
        .where((p) => p.status == 'Available')
        .length;

    final maintenance = properties
        .where((p) => p.status == 'Maintenance')
        .length;

    final income = properties
        .where((p) => p.status == 'Rented' && p.rentPaid)
        .fold<double>(
      0,
          (sum, p) => sum + p.rent,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Property Overview 🏠',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Manage your properties and rental records.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 18),

        // RESPONSIVE STAT CARDS
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            final columns = width < 500 ? 2 : 4;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: width < 380 ? 1.25 : 1.45,
              ),
              itemBuilder: (context, index) {
                final cards = [
                  (
                  'Properties',
                  '$total',
                  Icons.home_work,
                  ),
                  (
                  'Rented',
                  '$rented',
                  Icons.key,
                  ),
                  (
                  'Available',
                  '$available',
                  Icons.home,
                  ),
                  (
                  'Maintenance',
                  '$maintenance',
                  Icons.build,
                  ),
                ];

                final card = cards[index];

                return StatCard(
                  title: card.$1,
                  value: card.$2,
                  icon: card.$3,
                );
              },
            );
          },
        ),

        const SizedBox(height: 18),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 25,
                  backgroundColor: Color(0xFFD6A84F),
                  foregroundColor: Colors.black,
                  child: Icon(
                    Icons.account_balance_wallet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Collected Rent',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rs ${income.toStringAsFixed(0)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          'Recent Properties',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        ...properties.take(4).map(
              (p) => PropertyTile(property: p),
        ),
      ],
    );
  }
}

// ================= STAT CARD =================

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: const Color(0xFFD6A84F),
              foregroundColor: Colors.black,
              child: Icon(
                icon,
                size: 19,
              ),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= PROPERTIES =================

class PropertiesPage extends StatefulWidget {
  final List<Property> properties;
  final VoidCallback onChanged;
  final VoidCallback onAdd;

  const PropertiesPage({
    super.key,
    required this.properties,
    required this.onChanged,
    required this.onAdd,
  });

  @override
  State<PropertiesPage> createState() =>
      _PropertiesPageState();
}

class _PropertiesPageState extends State<PropertiesPage> {
  String search = '';
  String filter = 'All';

  @override
  Widget build(BuildContext context) {
    final list = widget.properties.where((p) {
      final q = search.toLowerCase();

      final matchSearch =
          p.name.toLowerCase().contains(q) ||
              p.location.toLowerCase().contains(q) ||
              p.tenant.toLowerCase().contains(q);

      final matchFilter =
          filter == 'All' || p.status == filter;

      return matchSearch && matchFilter;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            12,
            16,
            10,
          ),
          child: TextField(
            onChanged: (value) {
              setState(() {
                search = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search properties...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFF1A2520),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            children: [
              'All',
              'Available',
              'Rented',
              'Maintenance',
            ]
                .map(
                  (s) => Padding(
                padding: const EdgeInsets.only(
                  right: 8,
                ),
                child: ChoiceChip(
                  label: Text(s),
                  selected: filter == s,
                  onSelected: (_) {
                    setState(() {
                      filter = s;
                    });
                  },
                ),
              ),
            )
                .toList(),
          ),
        ),

        const SizedBox(height: 6),

        Expanded(
          child: list.isEmpty
              ? const Center(
            child: Text('No properties found'),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final p = list[i];

              return PropertyTile(
                property: p,
                actions: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'delete') {
                      widget.properties.removeWhere(
                            (x) => x.id == p.id,
                      );

                      await Storage.save(
                        widget.properties,
                      );

                      widget.onChanged();

                      if (mounted) {
                        setState(() {});
                      }
                    }

                    if (value == 'edit') {
                      await editProperty(p);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> editProperty(Property p) async {
    final name = TextEditingController(text: p.name);
    final location =
    TextEditingController(text: p.location);
    final tenant =
    TextEditingController(text: p.tenant);
    final phone =
    TextEditingController(text: p.phone);
    final rent =
    TextEditingController(text: p.rent.toString());

    String type = p.type;
    String status = p.status;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialog) {
            return AlertDialog(
              title: const Text('Edit Property'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: name,
                      decoration:
                      const InputDecoration(
                        labelText: 'Property Name',
                      ),
                    ),
                    TextField(
                      controller: location,
                      decoration:
                      const InputDecoration(
                        labelText: 'Location',
                      ),
                    ),
                    TextField(
                      controller: tenant,
                      decoration:
                      const InputDecoration(
                        labelText: 'Tenant',
                      ),
                    ),
                    TextField(
                      controller: phone,
                      decoration:
                      const InputDecoration(
                        labelText: 'Phone',
                      ),
                    ),
                    TextField(
                      controller: rent,
                      keyboardType: TextInputType.number,
                      decoration:
                      const InputDecoration(
                        labelText: 'Monthly Rent',
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration:
                      const InputDecoration(
                        labelText: 'Type',
                      ),
                      items: const [
                        'Apartment',
                        'House',
                        'Commercial',
                        'Office',
                      ]
                          .map(
                            (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ),
                      )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setDialog(() {
                            type = v;
                          });
                        }
                      },
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration:
                      const InputDecoration(
                        labelText: 'Status',
                      ),
                      items: const [
                        'Available',
                        'Rented',
                        'Maintenance',
                      ]
                          .map(
                            (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ),
                      )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setDialog(() {
                            status = v;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    p.name = name.text.trim();
                    p.location = location.text.trim();
                    p.tenant = tenant.text.trim();
                    p.phone = phone.text.trim();
                    p.rent =
                        double.tryParse(rent.text) ?? p.rent;
                    p.type = type;
                    p.status = status;

                    await Storage.save(widget.properties);
                    widget.onChanged();

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );

    name.dispose();
    location.dispose();
    tenant.dispose();
    phone.dispose();
    rent.dispose();
  }
}

// ================= PROPERTY TILE =================

class PropertyTile extends StatelessWidget {
  final Property property;
  final Widget? actions;

  const PropertyTile({
    super.key,
    required this.property,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 23,
              backgroundColor: Color(0xFFD6A84F),
              foregroundColor: Colors.black,
              child: Icon(Icons.home_work),
            ),
            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    property.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${property.type} • ${property.location}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    property.tenant.isEmpty
                        ? 'No tenant'
                        : property.tenant,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            if (actions != null)
              actions!
            else
              Flexible(
                child: Text(
                  'Rs ${property.rent.toStringAsFixed(0)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ================= TENANTS =================

class TenantsPage extends StatelessWidget {
  final List<Property> properties;
  final VoidCallback onChanged;

  const TenantsPage({
    super.key,
    required this.properties,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tenants = properties
        .where((p) => p.tenant.isNotEmpty)
        .toList();

    if (tenants.isEmpty) {
      return const Center(
        child: Text('No tenants found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tenants.length,
      itemBuilder: (context, index) {
        final p = tenants[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFD6A84F),
                  foregroundColor: Colors.black,
                  child: Icon(Icons.person),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        p.tenant,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        p.phone.isEmpty
                            ? 'No phone'
                            : p.phone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Rs ${p.rent.toStringAsFixed(0)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ================= RENT =================

class RentPage extends StatefulWidget {
  final List<Property> properties;
  final VoidCallback onChanged;

  const RentPage({
    super.key,
    required this.properties,
    required this.onChanged,
  });

  @override
  State<RentPage> createState() => _RentPageState();
}

class _RentPageState extends State<RentPage> {
  @override
  Widget build(BuildContext context) {
    final rented = widget.properties
        .where((p) => p.status == 'Rented')
        .toList();

    if (rented.isEmpty) {
      return const Center(
        child: Text('No rented properties'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rented.length,
      itemBuilder: (context, index) {
        final p = rented[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        p.tenant.isEmpty
                            ? p.name
                            : p.tenant,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      p.rentPaid ? 'PAID' : 'DUE',
                      style: TextStyle(
                        color: p.rentPaid
                            ? Colors.greenAccent
                            : Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 3),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Rs ${p.rent.toStringAsFixed(0)} / month',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    TextButton(
                      onPressed: () async {
                        setState(() {
                          p.rentPaid = !p.rentPaid;
                        });

                        await Storage.save(
                          widget.properties,
                        );

                        widget.onChanged();
                      },
                      child: Text(
                        p.rentPaid
                            ? 'Mark Due'
                            : 'Mark Paid',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ================= REPORTS =================

class ReportsPage extends StatelessWidget {
  final List<Property> properties;

  const ReportsPage({
    super.key,
    required this.properties,
  });

  @override
  Widget build(BuildContext context) {
    final rented = properties
        .where((p) => p.status == 'Rented')
        .length;

    final available = properties
        .where((p) => p.status == 'Available')
        .length;

    final maintenance = properties
        .where((p) => p.status == 'Maintenance')
        .length;

    final paid = properties
        .where((p) => p.status == 'Rented' && p.rentPaid)
        .fold<double>(
      0,
          (sum, p) => sum + p.rent,
    );

    final due = properties
        .where((p) => p.status == 'Rented' && !p.rentPaid)
        .fold<double>(
      0,
          (sum, p) => sum + p.rent,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Property Reports',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        ReportCard(
          title: 'Total Properties',
          value: '${properties.length}',
          icon: Icons.home_work,
        ),
        ReportCard(
          title: 'Rented',
          value: '$rented',
          icon: Icons.key,
        ),
        ReportCard(
          title: 'Available',
          value: '$available',
          icon: Icons.home,
        ),
        ReportCard(
          title: 'Maintenance',
          value: '$maintenance',
          icon: Icons.build,
        ),
        ReportCard(
          title: 'Rent Collected',
          value: 'Rs ${paid.toStringAsFixed(0)}',
          icon: Icons.check_circle,
        ),
        ReportCard(
          title: 'Rent Due',
          value: 'Rs ${due.toStringAsFixed(0)}',
          icon: Icons.warning,
        ),
      ],
    );
  }
}

// ================= REPORT CARD =================

class ReportCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const ReportCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundColor: Color(0xFFD6A84F),
              foregroundColor: Colors.black,
              child: Icon(Icons.analytics),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}