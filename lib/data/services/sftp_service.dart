import 'dart:convert';
import 'dart:io';
import 'package:dartssh2/dartssh2.dart';
import '../models/file_details.dart';
import '../models/remote_file.dart';
import '../models/sftp_permission_models.dart';
import '../models/ssh_connection.dart';

class SftpService {
  SftpClient? _sftpClient;
  SSHClient? _sshClient;

  // Method to establish connection
  Future<void> connect(SSHConnection connection) async {
    try {
      _sshClient = SSHClient(
        await SSHSocket.connect(
          connection.host,
          connection.port,
          timeout: const Duration(seconds: 10),
        ),
        username: connection.username,
        onPasswordRequest: () => connection.password ?? '',
        identities: connection.privateKey != null ? SSHKeyPair.fromPem(connection.privateKey!) : null,
      );

      _sftpClient = await _sshClient!.sftp();
    } 
    catch (e) {
      throw Exception('Failed to connect to SFTP server: $e');
    }
  }

  // Check if connected
  bool get isConnected => _sftpClient != null && _sshClient != null;

  // Ensure connection is established
  void _ensureConnected() {
    if (!isConnected) {
      throw Exception('Not connected to SFTP server');
    }
  }

  // List directory contents
  Future<List<RemoteFile>> listDirectory(String path) async {
    _ensureConnected();
    try {
      final list = await _sftpClient!.listdir(path);
      return list.map((file) => RemoteFile.fromStat(file, path)).toList();
    } catch (e) {
      throw Exception('Failed to list directory contents: $e');
    }
  }

  // Get file information
  Future<RemoteFile> getFileInfo(String path) async {
    _ensureConnected();
    try {
      final fileName = path.split('/').last;
      final parentPath = path.substring(0, path.length - fileName.length);
      final stat = await _sftpClient!.stat(path);

      // Create SftpName with required attr parameter
      final sftpName = SftpName(
        filename: fileName,
        longname: stat.toString(),
        attr: stat,
      );

      return RemoteFile.fromStat(sftpName, parentPath);
    }
    catch (e) {
      throw Exception('Failed to get file info: $e');
    }
  }

  // Rename file
  Future<void> renameFile(String oldPath, String newPath) async {
    _ensureConnected();
    try {
      await _sftpClient!.rename(oldPath, newPath);
    } catch (e) {
      throw Exception('Failed to rename file: $e');
    }
  }

  // Copy file
  Future<void> copyFile(String sourcePath, String destinationPath) async {
    _ensureConnected();
    try {
      // Read source file
      final sourceFile = await _sftpClient!.open(sourcePath, mode: SftpFileOpenMode.read);
      final data = await sourceFile.readBytes();
      await sourceFile.close();

      // Write to destination
      final destFile = await _sftpClient!.open(
        destinationPath,
        mode: SftpFileOpenMode.create | SftpFileOpenMode.write,
      );
      await destFile.writeBytes(data);
      await destFile.close();
    } catch (e) {
      throw Exception('Failed to copy file: $e');
    }
  }

  // Move file
  Future<void> moveFile(String sourcePath, String destinationPath) async {
    _ensureConnected();
    try {
      await copyFile(sourcePath, destinationPath);
      await deleteFile(sourcePath);
    } catch (e) {
      throw Exception('Failed to move file: $e');
    }
  }

  // Delete file
  Future<void> deleteFile(String path) async {
    _ensureConnected();
    try {
      await _sftpClient!.remove(path);
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  // Upload file
  Future<void> uploadFile(String localPath, String remotePath) async {
    _ensureConnected();
    try {
      final file = File(localPath);
      final data = await file.readAsBytes();

      final remoteFile = await _sftpClient!.open(
        remotePath,
        mode: SftpFileOpenMode.create | SftpFileOpenMode.write,
      );
      await remoteFile.writeBytes(data);
      await remoteFile.close();
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  // Download file
  Future<void> downloadFile({required String remotePath, required String localPath, required Function onProgress}) async {
    _ensureConnected();
    try {
      final remoteFile = await _sftpClient!.open(remotePath, mode: SftpFileOpenMode.read);
      final data = await remoteFile.readBytes();
      await remoteFile.close();

      final file = File(localPath);
      await file.writeAsBytes(data);
    }
    catch (e) {
      throw Exception('Failed to download file: $e');
    }
  }

  // Get file details using file and stat commands
  Future<FileDetails> getFileDetails(String path) async {
    _ensureConnected();
    try {
      // Execute 'file' command and convert result to string
      final fileResult = utf8.decode(
          await _sshClient!.run('file "$path"')
      );

      // Execute 'stat' command and convert result to string
      final statResult = utf8.decode(
          await _sshClient!.run('stat "$path"')
      );

      return FileDetails.fromCommandOutputs(
        path: path,
        fileOutput: fileResult,
        statOutput: statResult,
      );
    }
    catch (e) {
      throw Exception('Failed to get file details: $e');
    }
  }

  // Cleanup resources
  Future<void> disconnect() async {
    try {
      _sftpClient?.close();
      _sshClient?.close();
      _sftpClient = null;
      _sshClient = null;
    } catch (e) {
      throw Exception('Failed to disconnect: $e');
    }
  }

  // Change the permissions of file/directory
  Future<void> changePermissions(String path, String permissions, {bool recursive = false}) async {
    _ensureConnected();
    try {
      final command = recursive
          ? 'chmod -R $permissions "$path"'
          : 'chmod $permissions "$path"';

      final result = await _sshClient!.run(command);
      if (result.isNotEmpty) {
        throw Exception(utf8.decode(result));
      }
    } catch (e) {
      throw Exception('Failed to change permissions: $e');
    }
  }

  // Get the list of users from server
  Future<List<UnixUser>> getUsers() async {
    _ensureConnected();
    try {
      final result = await _sshClient!.run('cat /etc/passwd');
      return utf8.decode(result)
          .split('\n')
          .where((line) => line.isNotEmpty)
          .map((line) => UnixUser.fromString(line))
          .toList();
    } catch (e) {
      throw Exception('Failed to get users: $e');
    }
  }

  // Get the list of groups from server
  Future<List<UnixGroup>> getGroups() async {
    _ensureConnected();
    try {
      final result = await _sshClient!.run('cat /etc/group');
      return utf8.decode(result)
          .split('\n')
          .where((line) => line.isNotEmpty)
          .map((line) => UnixGroup.fromString(line))
          .toList();
    } catch (e) {
      throw Exception('Failed to get groups: $e');
    }
  }

  // Change the ownership of a file/directory
  Future<void> changeOwner(String path, String owner, String group, {bool recursive = false}) async {
    _ensureConnected();
    try {
      final command = recursive
          ? 'chown -R $owner:$group "$path"'
          : 'chown $owner:$group "$path"';

      final result = await _sshClient!.run(command);
      if (result.isNotEmpty) {
        throw Exception(utf8.decode(result));
      }
    } catch (e) {
      throw Exception('Failed to change owner: $e');
    }
  }

  // Create a file on server
  Future<void> createFile(String path) async {
    _ensureConnected();
    try {
      final command = 'touch $path';
      final result = await _sshClient!.run(command);
      if (result.isNotEmpty) throw Exception(utf8.decode(result));
    }
    catch(e) {
      throw Exception("Failed to create file in $path \n $e");
    }
  }

  // Create a directory on server
  Future<void> createFolder(String path) async {
    _ensureConnected();
    try {
      final command = 'mkdir -p $path';
      final result = await _sshClient!.run(command);
      if (result.isNotEmpty) throw Exception(utf8.decode(result));
    }
    catch(e) {
      throw Exception('Failed to create directory in $path \n $e');
    }
  }
}
