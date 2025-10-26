import 'package:flutter/material.dart';
import '../../organisms/navbar.dart';

class TableListPage extends StatelessWidget {
  const TableListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Navbar(title: 'Table List'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Simple Table',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Country')),
                        DataColumn(label: Text('City')),
                        DataColumn(label: Text('Salary')),
                      ],
                      rows: const [
                        DataRow(cells: [
                          DataCell(Text('Dakota Rice')),
                          DataCell(Text('Niger')),
                          DataCell(Text('Oud-Turnhout')),
                          DataCell(Text('\$36,738')),
                        ]),
                        DataRow(cells: [
                          DataCell(Text('Minerva Hooper')),
                          DataCell(Text('Curaçao')),
                          DataCell(Text('Sinaai-Waas')),
                          DataCell(Text('\$23,789')),
                        ]),
                        DataRow(cells: [
                          DataCell(Text('Sage Rodriguez')),
                          DataCell(Text('Netherlands')),
                          DataCell(Text('Baileux')),
                          DataCell(Text('\$56,142')),
                        ]),
                        DataRow(cells: [
                          DataCell(Text('Philip Chaney')),
                          DataCell(Text('Korea, South')),
                          DataCell(Text('Overland Park')),
                          DataCell(Text('\$38,735')),
                        ]),
                        DataRow(cells: [
                          DataCell(Text('Doris Greene')),
                          DataCell(Text('Malawi')),
                          DataCell(Text('Feldkirchen in Kärnten')),
                          DataCell(Text('\$63,542')),
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}