var wavesurfer;

function initializeWavesurfer(args) {
    console.log("hit initializeWavesurfer in js with " + args.containerId + " and " + args.songUrl);
    wavesurfer = WaveSurfer.create({
        container: '#' + args.containerId
    });
    wavesurfer.load(args.songUrl);
    return (wavesurfer !== 'undefined');
}
