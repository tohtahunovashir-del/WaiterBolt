import SwiftUI
import PhotosUI

struct ScannerView: View {
    @EnvironmentObject var scannerVM: ScannerViewModel
    @EnvironmentObject var menuVM: MenuViewModel
    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let img = scannerVM.selectedImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 240)
                            .cornerRadius(16)
                            .shadow(radius: 6)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.appSecondary)
                            .frame(height: 220)
                            .overlay(
                                VStack(spacing: 10) {
                                    Image(systemName: "camera.viewfinder").font(.system(size: 48)).foregroundColor(.secondary)
                                    Text("Сфотографируйте меню").foregroundColor(.secondary)
                                }
                            )
                    }

                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label("Выбрать фото", systemImage: "photo")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.appPrimary)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                    .onChange(of: photoItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let img = UIImage(data: data) {
                                scannerVM.process(image: img)
                            }
                        }
                    }

                    if scannerVM.isProcessing {
                        ProgressView("Распознавание...")
                            .padding()
                    }

                    if let err = scannerVM.errorMessage {
                        Text(err).foregroundColor(.red).font(.system(size: 13)).padding(.horizontal)
                    }

                    if !scannerVM.recognized.isEmpty {
                        VStack(spacing: 10) {
                            HStack {
                                Text("Распознанные позиции").font(.system(size: 16, weight: .bold))
                                Spacer()
                                Text("\(scannerVM.recognized.filter { $0.isSelected }.count) выбрано").font(.system(size: 13)).foregroundColor(.secondary)
                            }
                            ForEach(scannerVM.recognized) { item in
                                RecognizedRow(item: item)
                            }
                            PrimaryButton("Импортировать выбранные (\(scannerVM.recognized.filter { $0.isSelected }.count))", icon: "square.and.arrow.down") {
                                scannerVM.importSelected()
                                menuVM.load()
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Сканер меню")
        }
    }
}

struct RecognizedRow: View {
    @EnvironmentObject var scannerVM: ScannerViewModel
    let item: RecognizedMenuItem

    var body: some View {
        HStack(spacing: 10) {
            Button { scannerVM.toggleSelection(item) } label: {
                Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isSelected ? .appPrimary : .secondary)
                    .font(.title2)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                TextField("Название", text: Binding(
                    get: { item.name },
                    set: { scannerVM.updateName(item, name: $0) }
                ))
                .font(.system(size: 15, weight: .semibold))
                HStack {
                    TextField("Цена", value: Binding(
                        get: { item.price },
                        set: { scannerVM.updatePrice(item, price: $0) }
                    ), format: .number)
                    .keyboardType(.decimalPad)
                    .frame(width: 90)
                    Picker("", selection: Binding(
                        get: { item.category },
                        set: { scannerVM.updateCategory(item, category: $0) }
                    )) {
                        ForEach(MenuCategory.allCases) { c in Text(c.rawValue).tag(c) }
                    }
                    .pickerStyle(.menu)
                }
            }
        }
        .padding(12)
        .background(Color.appSecondary)
        .cornerRadius(14)
    }
}
