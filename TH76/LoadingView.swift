//
//  LoadingView.swift
//  TH76
//
//  Created by IGOR on 29/09/2025.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {

        ZStack {
            
            Color.white
                .ignoresSafeArea()
            
            VStack {
                
                Image("76")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 130)
            }
            
            VStack {
                
                Spacer()
                
                ProgressView()
                    .padding(40)
            }
        }
    }
}

#Preview {
    LoadingView()
}
