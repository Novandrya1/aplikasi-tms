class PaginationHelper<T> {
  List<T> _items = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  
  List<T> get items => _items;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  int get currentPage => _currentPage;
  
  Future<void> loadPage(Future<Map<String, dynamic>> Function(int page) loader) async {
    if (_isLoading || !_hasMore) return;
    
    _isLoading = true;
    try {
      final result = await loader(_currentPage);
      final newItems = List<T>.from(result['data'] ?? []);
      
      if (_currentPage == 1) {
        _items = newItems;
      } else {
        _items.addAll(newItems);
      }
      
      _totalPages = result['total_pages'] ?? 1;
      _hasMore = _currentPage < _totalPages;
      _currentPage++;
    } finally {
      _isLoading = false;
    }
  }
  
  void reset() {
    _items.clear();
    _currentPage = 1;
    _hasMore = true;
    _isLoading = false;
  }
}