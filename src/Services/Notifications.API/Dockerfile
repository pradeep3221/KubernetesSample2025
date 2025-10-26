FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY ["src/Services/Notifications.API/Notifications.API.csproj", "src/Services/Notifications.API/"]
COPY ["src/Shared/Shared.Contracts/Shared.Contracts.csproj", "src/Shared/Shared.Contracts/"]
COPY ["src/Shared/Shared.Observability/Shared.Observability.csproj", "src/Shared/Shared.Observability/"]
RUN dotnet restore "src/Services/Notifications.API/Notifications.API.csproj"
COPY . .
WORKDIR "/src/src/Services/Notifications.API"
RUN dotnet build "Notifications.API.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "Notifications.API.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Notifications.API.dll"]

