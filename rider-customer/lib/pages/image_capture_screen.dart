import 'package:flutter/material.dart';

class ImageCaptureScreen extends StatefulWidget {
  final Function(String imagePath) onImageCapture;

  const ImageCaptureScreen({
    super.key,
    required this.onImageCapture,
  });

  @override
  State<ImageCaptureScreen> createState() => _ImageCaptureScreenState();
}

class _ImageCaptureScreenState extends State<ImageCaptureScreen> {
  final List<String> _capturedImages = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Order Images'),
        elevation: 0,
      ),
      body: _capturedImages.isEmpty ? _buildEmptyState() : _buildImageGrid(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showImageOptions,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Add Image'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No Images Added',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Add images of the items you want to order',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showImageOptions,
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Capture First Image'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _capturedImages.length,
      itemBuilder: (context, index) {
        return _buildImageCard(_capturedImages[index], index);
      },
    );
  }

  Widget _buildImageCard(String imagePath, int index) {
    return Card(
      elevation: 2,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: Colors.grey[200],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Image ${index + 1}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Image ${index + 1}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Image',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Take Photo'),
              subtitle: const Text('Capture image using camera'),
              onTap: () {
                Navigator.pop(context);
                _captureFromCamera();
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.image, color: Colors.green),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select image from your gallery'),
              onTap: () {
                Navigator.pop(context);
                _selectFromGallery();
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.link, color: Colors.orange),
              title: const Text('Add Link'),
              subtitle: const Text('Add image URL'),
              onTap: () {
                Navigator.pop(context);
                _addImageLink();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _captureFromCamera() {
    // TODO: Implement camera integration
    // Example using image_picker package:
    // final ImagePicker picker = ImagePicker();
    // final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    // if (photo != null) {
    //   setState(() {
    //     _capturedImages.add(photo.path);
    //   });
    // }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Camera not available in demo')),
    );

    // Mock implementation for demo
    setState(() {
      _capturedImages.add('camera_${DateTime.now().millisecond}');
    });
  }

  void _selectFromGallery() {
    // TODO: Implement gallery selection
    // Example using image_picker package:
    // final ImagePicker picker = ImagePicker();
    // final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    // if (image != null) {
    //   setState(() {
    //     _capturedImages.add(image.path);
    //   });
    // }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gallery access not available in demo')),
    );

    // Mock implementation for demo
    setState(() {
      _capturedImages.add('gallery_${DateTime.now().millisecond}');
    });
  }

  void _addImageLink() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Image URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Paste image URL here',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _capturedImages.add(controller.text);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Image added successfully')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removeImage(int index) {
    setState(() {
      _capturedImages.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image removed')),
    );
  }
}
