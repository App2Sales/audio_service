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

  // final stream = rootBundle.load("assets/sample.mp3").asStream();

  // final file = File("$root/sample.mp3.aes");
  // final stream = file.readAsBytes().asStream();

  // int _total = 0, _received = 0;

  final uri = Uri.parse(aesUrl);
  // final uri = Uri.parse(url);
  final client = http.Client();
  final request = http.Request('GET', uri);
  final response = await client.send(request);
  final stream = response.stream;

  // _total = response.contentLength ?? 0;


  // final accumulator = AccumulatorSink<List<int>>();

  final myCustomSource = MyCustomSource(
    remoteStream: stream,
    sourceLength: response.contentLength
  );

  // final streamController = myCustomSource.controller;
  // player.setAudioSource(myCustomSource, preload: true);

  // final stream = http.get(uri).asStream();


  player.setAudioSource(myCustomSource, preload: true);


  // stream.doOnDone(() {
  //   print("finished");

  //   // final fullDecrypted = teste.events.single;
  //   // streamController.add(fullDecrypted);
    
  //   // player.setAudioSource(myCustomSource, preload: true);

  //   // player.play();

  //   // // print("[Accumulator] - $fullEncrypted");


  //   // enc.Encrypted en = enc.Encrypted(Uint8List.fromList(fullEncrypted));
  //   // final decrypted =
  //   //     MyEncrypt.myEncrypter.decryptBytes(en, iv: MyEncrypt.myIV);

  //   // streamController.add(decrypted);

  //   // player.setAudioSource(myCustomSource);
  // }).doOnData((event) {
  //   _received += event.length;

  //   print("data: ${event.length}");

  //   final decrypted = decrypt(event);
  //   streamController.add(decrypted);

  //   print("${(_received/_total)*100}% - ${[_received, _total]}");
  // }).listen((event) {

  //   // final list = event.buffer.asUint8List();
  //   // final list = event.bodyBytes;

  //   // final encrypted =
  //   //     MyEncrypt.myEncrypter.encryptBytes(list, iv: MyEncrypt.myIV).bytes;
  //   // final decrypted = decrypt(Uint8List.fromList(event));
  //   // final encryptedBytes = base64Decode(event);
  //   // final encrypted = encrypt(event.buffer.asUint8List());
  //   // final decrypted = decrypt(encrypted);
  //   // final decrypted = decrypt(event.buffer.asUint8List());
  //   // final decrypted = decrypt(event);
  //   // streamController.add(decrypted);
  //   // streamController.add(event);
  //   // streamController.add(event);
  //   // final decrypted = decrypt(list);

  //   // final encrypted = encrypt(event);
  //   // final decrypted = decrypt(encrypted);

  //   // teste.add(encrypted);
  //   // teste.add(decrypted);
  //   // bytesHandler(encrypted);

  //   // print("${(_received/_total)*100}% - ${[_received, _total]}");
  // });

  // var firstChunk = utf8.encode("foo");
  // var secondChunk = utf8.encode("bar");

  // var output = AccumulatorSink<Digest>();

  // teste.add(firstChunk);

  // var input = sha1.startChunkedConversion(output);
  // input.add(firstChunk);
  // input.add(secondChunk); // call `add` for every chunk of input data
  // input.close();
  // var digest = output.events.single;

  // print("Digest as bytes: ${digest.bytes}");
  // print("Digest as hex string: $digest");

  runApp(const MyApp());
}

void bytesHandler(List<int> bytes) {
  // print("[bytesHandler] -> $bytes");
}

List<int> encrypt(List<int> bytes) {
  return MyEncrypt.myEncrypter.encryptBytes(bytes, iv: MyEncrypt.myIV).bytes;
}

List<int> decrypt(List<int> encryptedBytes) {
  // enc.Encrypted en = enc.Encrypted(Uint8List.fromList(encryptedBytes));
  enc.Encrypted en = enc.Encrypted(Uint8List.fromList(encryptedBytes));
  // final result = MyEncrypt.myEncrypter.decrypt(en, iv: MyEncrypt.myIV);
  // return utf8.encode(result.toString());
  // return Uint8List.fromList(result.codeUnits);
  return MyEncrypt.myEncrypter.decryptBytes(en, iv: MyEncrypt.myIV);
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
  late final StreamController<List<int>> _controller;
  late final Stream<List<int>> _remoteStream;
  
  final int? sourceLength;

  final List<int> _decryptedBytes = [];
  // final AccumulatorSink<List<int>> _accumulator = AccumulatorSink<List<int>>();

  Stream<List<int>> get _decryptedBytesStream => _controller.stream;

  int _decryptedStart = 0;
  
  MyCustomSource({
    required Stream<List<int>> remoteStream,
    this.sourceLength
  }) {
    _remoteStream = remoteStream
      .doOnData((bytes) {
        final decrypted = decrypt(bytes);
        _decryptedBytes.addAll(decrypted);
      })
      .doOnDone(() async {
        await Future<void>.delayed(const Duration(milliseconds: 3000));
        _controller.close();
      });

    _controller = StreamController<List<int>>.broadcast(
      onListen: () {
        if (_decryptedBytes.isNotEmpty && _decryptedStart == 0) {
          _addOnController();
        }

        _remoteStream.listen((bytes) {
          _addOnController();
        });
      },
    );
  }

  void _addOnController() {
    _controller.add(_decryptedBytes.sublist(_decryptedStart));
    _decryptedStart = _decryptedBytes.length;
  }

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final length = sourceLength ?? _decryptedBytes.length;

    start ??= 0;
    end ??= length;

    return StreamAudioResponse(
      sourceLength: length,
      contentLength: end - start,
      offset: start,
      stream: _decryptedBytesStream,
      contentType: 'audio/mpeg',
    );
  }
}
