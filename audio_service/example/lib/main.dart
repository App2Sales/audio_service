// ignore_for_file: public_member_api_docs

// FOR MORE EXAMPLES, VISIT THE GITHUB REPOSITORY AT:
//
//  https://github.com/ryanheise/audio_service
//
// This example implements a minimal audio handler that renders the current
// media item and playback state to the system notification and responds to 4
// media actions:
//
// - play
// - pause
// - seek
// - stop
//
// To run this example, use:
//
// flutter run

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_service/audio_service.dart';
import 'package:audio_service_example/common.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:http/http.dart' as http;
import 'package:pointycastle/export.dart' as pc;

// You might want to provide this using dependency injection rather than a
// global variable.
late AudioHandler _audioHandler;

class MyEncrypt {
  // static final myKey = enc.Key.fromSecureRandom(16); //AES-128
  static final myKey = enc.Key.fromUtf8("chavededezesseis"); //AES-128
  static final myIV = enc.IV.fromUtf8("ivdedezesseischr");
  // static final myEncrypter = enc.Encrypter(enc.AES(myKey));
  static final myEncrypter =
      enc.Encrypter(enc.AES(myKey, mode: enc.AESMode.ctr, padding: null));

  static final myDecrypter = pc.CTRStreamCipher(pc.AESEngine())
    ..init(false, pc.ParametersWithIV(
      pc.KeyParameter(myKey.bytes),
      myIV.bytes
    ));  

  static List<int> encrypt(List<int> bytes) {
    return myEncrypter.encryptBytes(bytes, iv: MyEncrypt.myIV).bytes;
  }

  static List<int> decrypt(List<int> encryptedBytes) {
    enc.Encrypted en = enc.Encrypted(Uint8List.fromList(encryptedBytes));      
    return myDecrypter.process(en.bytes);
    // return MyEncrypt.myEncrypter.decryptBytes(en, iv: MyEncrypt.myIV);
  }
}

bool first = true;

Future<void> main() async {
  _audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.ryanheise.myapp.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    ),
  );

  // await Permission.storage.request();
  // await Permission.accessMediaLocation.request();

  const url =
      "https://bucket.institutohesed.org.br:9000/appinstituto/hesed/Nov_Suplica_cortada_b607513bd5.mp3";

  const aesUrl =
      "https://firebasestorage.googleapis.com/v0/b/hesed-cd25b.appspot.com/o/encrypted.mp3%5B1%5D.aes?alt=media";

  // final stream = rootBundle.load("assets/sample.mp3").asStream();
  // final stream = rootBundle.load("assets/encrypted.mp3.aes").asStream();
  // final local = await rootBundle.load("assets/sample.mp3");

  // const root = "/storage/emulated/0/MyEncFolder";
  // await Directory(root).create(recursive: true);

  // final file = File("$root/sample.mp3.aes");
  // await file.writeAsBytes(encrypt(local.buffer.asUint8List()));
  // print(file.absolute.toString());

  // return;

  final uri = Uri.parse(aesUrl);
  final request = http.Request('GET', uri);
  final response = await request.send();
  final stream = response.stream;

  final myCustomSource = MyCustomSource(
    responseStream: stream,
    sourceLength: response.contentLength
  );


  player.setAudioSource(myCustomSource, preload: true);
  // player.pause();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Service Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Service Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Show media item title
            StreamBuilder<MediaItem?>(
              stream: _audioHandler.mediaItem,
              builder: (context, snapshot) {
                final mediaItem = snapshot.data;
                return Text(mediaItem?.title ?? '');
              },
            ),
            // Play/pause/stop buttons.
            StreamBuilder<bool>(
              stream: _audioHandler.playbackState
                  .map((state) => state.playing)
                  .distinct(),
              builder: (context, snapshot) {
                final playing = snapshot.data ?? false;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _button(Icons.fast_rewind, _audioHandler.rewind),
                    if (playing)
                      _button(Icons.pause, _audioHandler.pause)
                    else
                      _button(Icons.play_arrow, _audioHandler.play),
                    _button(Icons.stop, _audioHandler.stop),
                    _button(Icons.fast_forward, _audioHandler.fastForward),
                  ],
                );
              },
            ),
            // A seek bar.
            StreamBuilder<MediaState>(
              stream: _mediaStateStream,
              builder: (context, snapshot) {
                final mediaState = snapshot.data;
                return SeekBar(
                  duration: mediaState?.mediaItem?.duration ?? Duration.zero,
                  position: mediaState?.position ?? Duration.zero,
                  onChangeEnd: (newPosition) {
                    _audioHandler.seek(newPosition);
                  },
                );
              },
            ),
            // Display the processing state.
            StreamBuilder<AudioProcessingState>(
              stream: _audioHandler.playbackState
                  .map((state) => state.processingState)
                  .distinct(),
              builder: (context, snapshot) {
                final processingState =
                    snapshot.data ?? AudioProcessingState.idle;
                return Text(
                    "Processing state: ${describeEnum(processingState)}");
              },
            ),
          ],
        ),
      ),
    );
  }

  /// A stream reporting the combined state of the current media item and its
  /// current position.
  Stream<MediaState> get _mediaStateStream =>
      Rx.combineLatest2<MediaItem?, Duration, MediaState>(
          _audioHandler.mediaItem,
          AudioService.position,
          (mediaItem, position) => MediaState(mediaItem, position));

  IconButton _button(IconData iconData, VoidCallback onPressed) => IconButton(
        icon: Icon(iconData),
        iconSize: 64.0,
        onPressed: onPressed,
      );
}

class MediaState {
  final MediaItem? mediaItem;
  final Duration position;

  MediaState(this.mediaItem, this.position);
}

/// An [AudioHandler] for playing a single item.
final player = AudioPlayer();

class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  static final _item = MediaItem(
    id: 'https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3',
    album: "Science Friday",
    title: "A Salute To Head-Scratching Science",
    artist: "Science Friday and WNYC Studios",
    duration: const Duration(milliseconds: 5739820),
    artUri: Uri.parse(
        'https://media.wnyc.org/i/1400/1400/l/80/1/ScienceFriday_WNYCStudios_1400.jpg'),
  );

  /// Initialise our audio handler.
  AudioPlayerHandler() {
    // So that our clients (the Flutter UI and the system notification) know
    // what state to display, here we set up our audio handler to broadcast all
    // playback state changes as they happen via playbackState...
    player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    // ... and also the current media item via mediaItem.
    // mediaItem.add(_item);

    // // Load the player.
    // player.setAudioSource(AudioSource.uri(Uri.parse(_item.id)));
  }

  // In this simple example, we handle only 4 actions: play, pause, seek and
  // stop. Any button press from the Flutter UI, notification, lock screen or
  // headset will be routed through to these 4 methods so that you can handle
  // your audio playback logic in one place.

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> stop() => player.stop();

  /// Transform a just_audio event into an audio_service state.
  ///
  /// This method is used from the constructor. Every event received from the
  /// just_audio player will be transformed into an audio_service state so that
  /// it can be broadcast to audio_service clients.
  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.rewind,
        if (player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[player.processingState]!,
      playing: player.playing,
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
      queueIndex: event.currentIndex,
    );
  }
}

class MyCustomSource extends StreamAudioSource {
  ///Controller for decrypted bytes stream.
  late final StreamController<List<int>> _decryptionController;

  ///Copy of [responseStream], but with "doOn" actions
  late final Stream<List<int>> _originalStream;
  
  ///Size of response's body 
  final int? sourceLength;

  ///Accumulator for decrypted bytes. The [_decryptedBytesStream] is internally listened after a delay.
  ///So, to workaround this behavior, the current accumulation will be immediately sent on first listen, and
  ///then the next bytes will be added.
  final List<int> _decryptedBytes = [];

  Stream<List<int>> get _decryptedBytesStream => _decryptionController.stream;

  ///Start position for decrypted addition.
  ///Ex.: firstLength = 100, {startPosition: 0, endPosition: 99}, so next addition will be {startPosition: 100, endPosition: 200}
  int _decryptedStart = 0;
  
  MyCustomSource({
    required Stream<List<int>> responseStream,
    this.sourceLength
  }) {    
    _originalStream = responseStream
      .doOnData((bytes) {
        final decrypted = MyEncrypt.decrypt(bytes);
        _decryptedBytes.addAll(decrypted);
      })
      .doOnDone(_closeStream)
      .doOnError((error, stackTrace) async {
        debugPrint(error.toString());
        debugPrint(stackTrace.toString());
        await _closeStream();
      });

    _decryptionController = StreamController<List<int>>.broadcast(
      onListen: () {
        if (_decryptedBytes.isNotEmpty && _decryptedStart == 0) {
          _addOnController();
        }

        _originalStream.listen((bytes) {
          _addOnController();
        });
      },
    );
  }

  void _addOnController() {
    _decryptionController.add(_decryptedBytes.sublist(_decryptedStart));
    _decryptedStart = _decryptedBytes.length;
  }

  Future<void> _closeStream() async {
    await Future<void>.delayed(const Duration(milliseconds: 3000));
    _decryptionController.close();
    debugPrint("Decryption stream was closed");
  }

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final length = sourceLength ?? _decryptedBytes.length;

    start ??= 0;
    end ??= length;

    return StreamAudioResponse(
      sourceLength: length,
      // contentLength: end - start,
      contentLength: -1,
      offset: start,
      stream: _decryptedBytesStream,
      contentType: 'audio/mpeg',
    );
  }
}
