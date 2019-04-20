class TransferStatus {
  // in case of any error occurred in mid of file transfer
  static const transferError = -1;
  // client couldn't connect to server
  static const connectionFailed = 1;
  // hit /done path using GET method
  static const transferComplete = 2;
  // hit /undone path using GET method
  static const transferIncomplete = 3;
  // client fetching file from PEER
  static const fileFetchInProgress = 4;
  // client completed fetching file from PEER
  static const fileFetched = 5;
  // server listening
  static const serverStarted = 6;
  // server stopped
  static const serverStopped = 7;
  // error during server init, led to failed start of server
  static const serverStartFailed = 8;
  // HTTP method used while fetching from PEER, not allowed by PEER
  static const fetchMethodNotAllowed = 9;
  // PEER denied access to requesting client
  static const fetchDenied = 10;
  // PEER shared file-list with with another PEER, these are the files which are to transmitted
  static const accessibleFileListShared = 11;

  // transferCode to String
  static const Map<int, String> transferCodeToString = {
    -1: 'Error during Tranfer',
    1: 'Peer Unavailable',
    2: 'Transfer Complete',
    3: 'Tranfer Incomplete',
    4: 'Fetching File',
    5: 'File Fetched',
    6: 'Server Started',
    7: 'Server Stopped',
    8: 'Failed to Start Server',
    9: 'Transmission Method not Allowed',
    10: 'Denied Access',
    11: 'Shared Accessible file List'
  };
}
