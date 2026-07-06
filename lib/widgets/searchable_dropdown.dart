import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category.dart';
import '../models/supplier.dart';

class SearchableDropdown<T> extends StatefulWidget {
  final List<T> items;
  final T? selectedItem;
  final String label;
  final String? hint;
  final IconData prefixIcon;
  final String Function(T) displayName;
  final String? Function(T?) validator;
  final void Function(T?) onChanged;
  final bool isLoading;
  final bool showSubtitle; // New parameter to control subtitle display

  const SearchableDropdown({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.label,
    required this.displayName,
    required this.validator,
    required this.onChanged,
    this.hint,
    this.prefixIcon = Icons.search,
    this.isLoading = false,
    this.showSubtitle = true,
  });

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<T> get _filteredItems {
    if (_searchQuery.isEmpty) return widget.items;
    return widget.items.where((item) {
      final name = widget.displayName(item).toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display selected item or button to select
        InkWell(
          onTap: () => _showSearchDialog(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(widget.prefixIcon, size: 20, color: Colors.grey.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.selectedItem != null
                            ? widget.displayName(widget.selectedItem as T)
                            : widget.hint ?? 'Select ${widget.label}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: widget.selectedItem != null
                              ? Colors.black
                              : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),

        // Validation error
        if (widget.validator(widget.selectedItem) != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              widget.validator(widget.selectedItem)!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.red.shade700,
              ),
            ),
          ),
      ],
    );
  }

  void _showSearchDialog() {
    _searchController.clear();
    setState(() => _searchQuery = '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                width: MediaQuery.of(context).size.width * 0.9,
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(widget.prefixIcon, color: Colors.white),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Select ${widget.label}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Search Field
                          TextField(
                            controller: _searchController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText:
                                  'Search ${widget.label.toLowerCase()}...',
                              prefixIcon: const Icon(Icons.search,
                                  color: Colors.white70),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear,
                                          color: Colors.white70),
                                      onPressed: () {
                                        _searchController.clear();
                                        setStateDialog(() {
                                          _searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.2),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              hintStyle: const TextStyle(color: Colors.white70),
                            ),
                            style: const TextStyle(color: Colors.white),
                            onChanged: (value) {
                              setStateDialog(() {
                                _searchQuery = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    // Items List
                    Expanded(
                      child: widget.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _filteredItems.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 64,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No ${widget.label.toLowerCase()} found',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Try a different search term',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(8),
                                  itemCount: _filteredItems.length,
                                  itemBuilder: (context, index) {
                                    final item = _filteredItems[index];
                                    final isSelected =
                                        widget.selectedItem == item;

                                    return ListTile(
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2E7D32)
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          widget.prefixIcon,
                                          color: const Color(0xFF2E7D32),
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(
                                        widget.displayName(item),
                                        style: GoogleFonts.poppins(
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? const Color(0xFF2E7D32)
                                              : null,
                                        ),
                                      ),
                                      subtitle: widget.showSubtitle
                                          ? _getSubtitle(item)
                                          : null,
                                      trailing: isSelected
                                          ? const Icon(Icons.check_circle,
                                              color: Color(0xFF2E7D32))
                                          : null,
                                      onTap: () {
                                        widget.onChanged(item);
                                        Navigator.pop(context);
                                      },
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget? _getSubtitle(T item) {
    // Use runtimeType to check the type
    if (item is Category) {
      if (item.description.isNotEmpty) {
        return Text(
          item.description,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      }
    } else if (item is Supplier) {
      if (item.phone.isNotEmpty) {
        return Text(
          '📞 ${item.phone}',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        );
      }
    }
    return null;
  }
}
