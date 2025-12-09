import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import '../../models/product.dart';
import '../models/enums.dart';

class ProductFormDialog extends ConsumerStatefulWidget {
  final Product? existing;

  const ProductFormDialog({super.key, this.existing});

  @override
  ConsumerState<ProductFormDialog> createState() => _FormState();
}

class _FormState extends ConsumerState<ProductFormDialog> {
  late TextEditingController name;
  late TextEditingController price;
  late TextEditingController desc;
  late TextEditingController models;

  ProductCategory category = ProductCategory.accessories;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.existing?.name);
    price = TextEditingController(text: widget.existing?.price.toString());
    desc = TextEditingController(text: widget.existing?.description);
    models = TextEditingController(
      text: widget.existing?.compatibleModels.join(", ") ?? "",
    );

    if (widget.existing != null) {
      category = widget.existing!.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return AlertDialog(
      title: Text(isEdit ? "Edit Product" : "Add Product"),
      content: SizedBox(
        width: 350,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: "Name")),
              TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Price")),
              TextField(controller: desc, decoration: const InputDecoration(labelText: "Description")),
              DropdownButtonFormField(
                initialValue: category,
                items: ProductCategory.values.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c.nameStr));
                }).toList(),
                onChanged: (v) => setState(() => category = v!),
                decoration: const InputDecoration(labelText: "Category"),
              ),
              TextField(
                controller: models,
                decoration: const InputDecoration(
                  labelText: "Compatible Models (comma separated)",
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        FilledButton(
          onPressed: () {
            ref.read(productsProvider.notifier).save(
              name.text,
              double.tryParse(price.text) ?? 0,
              desc.text,
              category,
              models.text.split(",").map((e) => e.trim()).toList(),
              widget.existing,
            );
            Navigator.pop(context);
          },
          child: Text(isEdit ? "Save" : "Add"),
        ),
      ],
    );
  }
}
