import PhotosUI
import UIKit
import MapKit

class TaskDetailViewController: UIViewController {

    @IBOutlet private weak var completedImageView: UIImageView!
    @IBOutlet private weak var completedLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var attachPhotoButton: UIButton!
    
    @IBOutlet private weak var mapView: MKMapView!

    var task: Task!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Register custom annotation view
        mapView.register(TaskAnnotationView.self, forAnnotationViewWithReuseIdentifier: TaskAnnotationView.identifier)
        
        // Set mapView delegate
        mapView.delegate = self

        // UI Candy
        mapView.layer.cornerRadius = 12

        // Set the initial region to the US
        let usCenter = CLLocationCoordinate2D(latitude: 37.0902, longitude: -95.7129) // Center of the US
        let usRegion = MKCoordinateRegion(center: usCenter, latitudinalMeters: 5000000, longitudinalMeters: 5000000)
        mapView.setRegion(usRegion, animated: false)

        updateUI()
        updateMapView()
    

    }

    /// Configure UI for the given task
    private func updateUI() {
        titleLabel.text = task.title
        descriptionLabel.text = task.description

        let completedImage = UIImage(systemName: task.isComplete ? "circle.inset.filled" : "circle")
        completedImageView.image = completedImage?.withRenderingMode(.alwaysTemplate)
        completedLabel.text = task.isComplete ? "Complete" : "Incomplete"

        let color: UIColor = task.isComplete ? .systemBlue : .tertiaryLabel
        completedImageView.tintColor = color
        completedLabel.textColor = color

        mapView.isHidden = false
        attachPhotoButton.isHidden = task.isComplete
       
    }

    @IBAction func didTapAttachPhotoButton(_ sender: Any) {
        // If authorized, show photo picker, otherwise request authorization.
        if PHPhotoLibrary.authorizationStatus(for: .readWrite) != .authorized {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
                switch status {
                case .authorized:
                    DispatchQueue.main.async {
                        self?.presentImagePicker()
                    }
                default:
                    DispatchQueue.main.async {
                        self?.presentGoToSettingsAlert()
                    }
                }
            }
        } else {
            presentImagePicker()
        }
    }

    private func presentImagePicker() {
        var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        config.filter = .images
        config.preferredAssetRepresentationMode = .current
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    func updateMapView() {
        guard let imageLocation = task.imageLocation else { return }

        let coordinate = imageLocation.coordinate
        let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        mapView.setRegion(region, animated: true)

        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PhotoSegue" {
            if let photoViewController = segue.destination as? PhotoViewController {
                photoViewController.task = task
            }
        }
    }
}

// Conform to PHPickerViewControllerDelegate
extension TaskDetailViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        let result = results.first
        guard let assetId = result?.assetIdentifier,
              let location = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil).firstObject?.location else {
            return
        }

        print("📍 Image location coordinate: \(location.coordinate)")

        guard let provider = result?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }

        provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            if let error = error {
                DispatchQueue.main.async { [weak self] in self?.showAlert(for: error) }
            }

            guard let image = object as? UIImage else { return }
            print("🌉 We have an image!")

            DispatchQueue.main.async { [weak self] in
                self?.task.set(image, with: location)
                self?.updateUI()
                self?.updateMapView()
            }
        }
    }
}

// Conform to MKMapViewDelegate
extension TaskDetailViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: TaskAnnotationView.identifier, for: annotation) as? TaskAnnotationView else {
            fatalError("Unable to dequeue TaskAnnotationView")
        }
        annotationView.configure(with: task.image)
        return annotationView
    }
}

// Helper methods to present various alerts
extension TaskDetailViewController {

    func presentGoToSettingsAlert() {
        let alertController = UIAlertController(
            title: "Photo Access Required",
            message: "In order to post a photo to complete a task, we need access to your photo library. You can allow access in Settings",
            preferredStyle: .alert)

        let settingsAction = UIAlertAction(title: "Settings", style: .default) { _ in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }

            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        }

        alertController.addAction(settingsAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }

    private func showAlert(for error: Error? = nil) {
        let alertController = UIAlertController(
            title: "Oops...",
            message: "\(error?.localizedDescription ?? "Please try again...")",
            preferredStyle: .alert)

        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)

        present(alertController, animated: true)
    }
}
